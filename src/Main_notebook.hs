-- |
-- Module      :  $Header$
-- Copyright   :  (c) 2013-2015 Galois, Inc.
-- License     :  BSD3
-- Maintainer  :  cryptol@galois.com
-- Stability   :  provisional
-- Portability :  portable

module Main where

import Notebook

import Cryptol.REPL.Command
import Cryptol.REPL.Monad (lName, lPath)
import qualified Cryptol.REPL.Monad as REPL

import qualified Cryptol.ModuleSystem as M
import Cryptol.Parser (defaultConfig, parseModule, Config(..))
import qualified Cryptol.Parser.AST as P
import qualified Cryptol.TypeCheck.AST as T
import Cryptol.Utils.PP (pp, pretty)
import qualified Cryptol.Version as Cryptol

import Control.Monad (forM_)

import qualified Data.Text as T
import qualified Data.Text.Lazy as LT
import Data.Version

import IHaskell.IPython.Kernel
import IHaskell.IPython.EasyKernel (easyKernel, KernelConfig(..))

import System.Environment (getArgs)

import Prelude.Compat

main :: IO ()
main = do
  args <- getArgs
  case args of
    ["kernel", profileFile] ->
      runNB $ do
        liftREPL loadPrelude `catch` \x -> io $ print $ pp x
        easyKernel profileFile cryptolConfig
    -- TODO: implement "install" command
    _ -> do
      putStrLn "Usage:"
      putStrLn $ "icryptol-kernel kernel FILE  -- run a kernel with FILE for "
              ++ "communication with the frontend"

-- Kernel Configuration --------------------------------------------------------
cryptolConfig :: KernelConfig NB String String
cryptolConfig = KernelConfig
  { kernelLanguageInfo = cryptolInfo
  , writeKernelspec = \_ -> return cryptolSpec
  , displayResult = displayRes
  , displayOutput = displayOut
  , completion = compl
  , inspectInfo = info
  , run = runCell
  , debug = False
  }
  where
    cryptolInfo = LanguageInfo {
        languageName = "cryptol"
      , languageVersion = showVersion Cryptol.version
      , languageFileExtension = ".cry"
      , languageCodeMirrorMode = "haskell"
      }
    cryptolSpec = KernelSpec {
        kernelDisplayName = "Cryptol"
      , kernelLanguage = "cryptol"
      , kernelCommand = ["icryptol-kernel", "kernel", "{connection_file}"]
      }
    displayRes str = [ DisplayData MimeHtml . T.pack $ str
                     , DisplayData PlainText . T.pack $ str
                     ]
    displayOut str = [ DisplayData PlainText . T.pack $ str ]
    -- TODO: implement completion
    compl cell _   = return (cell, [])
    -- TODO: implement info
    info _ _       = return Nothing
    runCell contents _clear nbPutStr = do
      putStrOrig <- liftREPL REPL.getPutStr
      liftREPL $ REPL.setPutStr nbPutStr
      let go = do
            handleAuto (T.unpack contents)
            return ("", Ok)
          handle exn =
            return (pretty exn, Err)
      (result, stat) <- catch go handle
      liftREPL $ REPL.setPutStr putStrOrig
      return (result, stat, "")

-- Input Handling --------------------------------------------------------------

-- | Determine whether the input is a module fragment or a series of
-- interactive commands, and behave accordingly.
handleAuto :: String -> NB ()
handleAuto str = do
  let cfg = defaultConfig { cfgSource = "<notebook>" }
      cmdParses cmd =
        case parseCommand (findNbCommand False) cmd of
          Just (Unknown _)     -> False
          Just (Ambiguous _ _) -> False
          _                    -> True
  case parseModule cfg (LT.pack str) of
    Right m -> handleModFrag m
    Left modExn -> do
      let cmds = lines str
      if and (map cmdParses cmds)
         then forM_ cmds handleCmd
         else raise (AutoParseError modExn)

parseModFrag :: String -> NB (P.Module P.PName)
parseModFrag str = liftREPL $ replParse (parseModule cfg . LT.pack) str
  where cfg = defaultConfig { cfgSource = "<notebook>" }

-- | Read a module fragment and incorporate it into the current context.
handleModFrag :: P.Module P.PName -> NB ()
handleModFrag m = do
  let m' = removeIncludes $ removeImports m
  old <- getTopDecls
  let new = modNamedDecls m'
      merged = updateNamedDecls old new
      doLoad = try $ liftREPL $ liftModuleCmd (M.loadModule "<notebook>" (moduleFromDecls nbName merged))
  em'' <- doLoad
  -- only update the top decls if the module successfully loaded
  case em'' of
    Left exn -> raise exn
    Right m'' -> do
      setTopDecls merged
      liftREPL $ REPL.setLoadedMod REPL.LoadedModule
                   { lName = Just (T.mName m'')
                   , lPath = "<notebook>"
                   }

readUntil :: (String -> Bool) -> NB String
readUntil shouldStop = unlines . reverse <$> go []
  where go xs = do
          line <- io getLine
          if shouldStop line
             then return xs
             else go (line : xs)

-- | Treat a line as an interactive command.
handleCmd :: String -> NB ()
handleCmd line =
    case parseCommand (findNbCommand False) line of
      Nothing -> return ()
      Just cmd -> liftREPL $ runCommand cmd
