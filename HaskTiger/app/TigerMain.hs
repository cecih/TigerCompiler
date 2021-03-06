module Main (main) where
import qualified System.Environment as Env
import System.Exit
import System.Console.GetOpt
import Control.Monad
import Data.Maybe
import Data.Either

import TigerAbs
import TigerParser
import TigerEscap
import TigerPretty
import TigerSeman

import Text.Parsec (runParser)

data Options = Options {
        optArbol :: Bool
        ,optDebEscap :: Bool
    }
    deriving Show

defaultOptions :: Options
defaultOptions = Options {optArbol = False, optDebEscap = False }

options :: [OptDescr (Options -> Options)]
options = [ Option ['a'] ["arbol"] (NoArg (\opts -> opts {optArbol = True})) "Muestra el AST luego de haber realizado el cálculo de escapes"
            , Option ['e'] ["escapada"] (NoArg (\opts -> opts {optDebEscap = True})) "Stepper escapadas"]

compilerOptions :: [String] -> IO (Options, [String])
compilerOptions argv = case getOpt Permute options argv of
                        (o,n,[]) -> return (foldl (flip id) defaultOptions o, n)
                        (_,_,errs) -> ioError (userError (concat errs ++ usageInfo header options))
    where
        header = "Se usa: tiger fileName [OPTIONS] "

showExp :: Exp -> IO ()
showExp e = do
    putStrLn "Mostramos el AST (PP Gracias a Emilio Lopez Junior)"
    putStrLn $ renderExp e

calculoEscapadas :: Exp -> Options -> IO Exp
calculoEscapadas rawAST _ = either (\err ->
                                       putStrLn "Error de Escap:" >>
                                       fail (show err)
                                      ) return (calcularEEsc rawAST)

main = do
    s:opts <- Env.getArgs
    (opts', _) <- compilerOptions opts
    sourceCode <- readFile s
    either (\err -> error $ "Parser error..." ++ show err) 
       (\ast ->
        do res <- calculoEscapadas ast opts' -- OJOTA: Efectos secundarios
           either (\a -> print $ "Error: " ++ show a) (\b -> print $ show b) (runLion res)) (runParser expression () s sourceCode)


