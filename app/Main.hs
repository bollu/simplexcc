{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
module Main where

import StgLanguage
import StgParser
import StgPushEnterMachine
import StgToIR
import IRToLLVM
import Stg
-- import StgLLVMBackend

import System.IO
import System.Environment
import System.Console.Haskeline
import Control.Monad.Trans.Class
import Control.Lens
import Control.Exception
import Control.Monad
import Data.List
import Data.Monoid
import ColorUtils

import Data.Foldable(for_)


import IR
import IRBuilder

import Options.Applicative

data CommandLineOptions = CommandLineOptions {
  -- | whether this should emit LLVM or not.
  emitLLVM :: Bool,
  -- | path to input file with STG.
  infilepath :: String,
  -- | path to output file to write LLVM IR.
  moutfilepath :: Maybe String
}

infilepathopt :: Parser (String)
infilepathopt = strOption (long "input file" <> short 'f' <> metavar "infilepath")

outfilepathopt :: Parser (Maybe String)
outfilepathopt = option (Just <$> str) (long "output file" <>
                                      short 'o' <>
                                      metavar "outfilepath" <>
                                      value Nothing)

emitLLVMOpt :: Parser Bool
emitLLVMOpt = switch (long "emit-llvm")

commandLineOptionsParser :: Parser CommandLineOptions
commandLineOptionsParser = CommandLineOptions <$> emitLLVMOpt <*> infilepathopt <*> outfilepathopt

commandLineOptionsParserInfo :: ParserInfo CommandLineOptions
commandLineOptionsParserInfo = info commandLineOptionsParser infomod where
    infomod = fullDesc <> progDesc "STG -> LLVM compiler" <> header "simplexhc"

repl :: InputT IO ()
repl = do
    lift . putStrLn $ "\n"
    line <- getInputLine ">"
    case line of
      Nothing -> repl
      Just (l) ->  do
        lift . compileAndRun $ l
        repl

  where
    compileAndRun :: String -> IO ()
    compileAndRun line = do

      putStrLn "interp: "
      let mInitState = tryCompileString line
      let mTrace = fmap genMachineTrace mInitState
      case mTrace of
          (Left err) -> putStrLn err
          (Right trace) -> putStr . getTraceString $ trace

getTraceString :: ([PushEnterMachineState], Maybe StgError) -> String
getTraceString (trace, mErr) =
  traceStr ++ "\n\n\nFinal:\n==================================\n" ++ errStr where
  errStr = case mErr of
            Nothing -> "Success"
            Just err -> show err ++ machineFinalStateLogStr
  traceStr = intercalate "\n\n==================================\n\n" (fmap show trace)
  machineFinalStateLogStr = if length trace == 0 then "" else "\nlog:\n====\n" ++ show ((last trace) ^. currentLog)

runFileInterp :: String -> IO ()
runFileInterp ipath = do
    raw <- Prelude.readFile ipath
    let mInitState = tryCompileString raw
    let trace = fmap genMachineTrace mInitState
    case trace of
          (Left compileErr) -> do
                                      putStrLn "compile error: "
                                      putStrLn  $ compileErr
          (Right trace) -> putStr . getTraceString $ trace

runFileLLVM :: String -- ^Input file path
               -> Maybe String -- ^Output file path
               -> IO ()
runFileLLVM ipath mopath = do
    raw <- Prelude.readFile ipath
    let mParse = parseString raw
    case mParse of
        (Left compileErr) -> do
                              putStrLn "compile error: "
                              putStrLn  $ compileErr
        (Right program) -> do
                             putStrLn "LLVM module: "
                             putStrLn "*** Internal IR :"
                             let module' = programToModule program
                             putStrLn . prettyToString $ module'
                             putStrLn "*** LLVM IR :"
                             str <- moduleToLLVMIRString module'
                             putStr  str
                             for_ mopath (\opath -> writeModuleLLVMIRStringToFile module' opath)
-- Input
main :: IO ()
main = do
    opts <- execParser commandLineOptionsParserInfo
    if infilepath opts == ""
        then runInputT defaultSettings repl
        else if emitLLVM opts == False
        then runFileInterp (infilepath opts)
        else runFileLLVM (infilepath opts) (moutfilepath opts)
