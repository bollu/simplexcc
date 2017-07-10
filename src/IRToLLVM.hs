module IRToLLVM where

import Control.Lens

import qualified LLVM.AST as AST
import LLVM.AST (Named(..))
import qualified LLVM.AST.Global as G
import qualified LLVM.CodeModel as CodeModel
import qualified LLVM.Module as Module
import LLVM.AST.Constant
import LLVM.AST.Type
import LLVM.AST.Constant (Constant)
import LLVM.AST.AddrSpace
import LLVM.AST.Instruction (Named, Instruction(Mul), Terminator)
import LLVM.AST.Instruction(Instruction(..))
import LLVM.AST.Linkage
import LLVM.AST.Visibility
import LLVM.AST.DLL
import LLVM.AST.CallingConvention as CC
import LLVM.AST.ThreadLocalStorage
import LLVM.AST.Attribute
import LLVM.Target
import LLVM.Context
import qualified Data.ByteString.Char8 as C8 (pack)
import qualified Data.ByteString as B
import qualified Data.ByteString.Short as B
         (ShortByteString, toShort, fromShort)
import Data.Char (chr)
import Data.Text.Prettyprint.Doc as PP
import ColorUtils


import qualified Data.Map.Strict as M
import IRBuilder
import IR as IR

bsToStr :: B.ByteString -> String
bsToStr = map (chr . fromEnum) . B.unpack

-- | Convert a 'String' to a 'ShortByteString'
strToShort :: String -> B.ShortByteString
strToShort = B.toShort . C8.pack

-- | Convert a 'String' to a 'AST.Name'
strToName :: String -> AST.Name
strToName = AST.Name . strToShort


moduleToLLVMIRString :: IR.Module -> IO IRString
moduleToLLVMIRString mod = error "unimplemented" 

-- | Construct the LLVM IR string corresponding to the program
{-
moduleIRString :: Program -> IO IRString
moduleIRString program = do
  putStrLn . show $ builder
  bsToStr <$> (withContext $
    \context ->
       (Module.withModuleFromAST context mod (Module.moduleLLVMAssembly)))
      where
        mod = mkModule (mkSTGDefinitions program builder)
        builder = mkBuilder program
-}

-- | Create a new module
mkModule :: [AST.Definition] ->  AST.Module
mkModule defs = AST.Module {
      AST.moduleName=B.toShort . C8.pack  $ "simplexhc",
      AST.moduleSourceFileName=B.toShort . C8.pack $ "simplexhc-thinair",
      AST.moduleDataLayout=Nothing,
      AST.moduleTargetTriple=Nothing,
      AST.moduleDefinitions=defs
}


type IRString = String


-- mkBoxedThunk

-- arg stack
-- return stack
-- global code
-- heap

-- eval
-- enter

i32val :: Int -> Constant
i32val val = Int 32 (fromIntegral val)

i32ty :: AST.Type
i32ty = AST.IntegerType 32

tagty :: Type
tagty = i32ty

type BindingId = Int
-- | Builder that maintains context of what we're doing when constructing IR.
{-
data Builder = Builder {
  bindings :: [Binding]
} 

instance Pretty Builder where
  pretty (Builder binds) = 
    vcat (zipWith prettyfn [1..] binds)
      where
        prettyfn :: Int -> Binding -> Doc a
        prettyfn = (\i b -> pretty i <+> pretty ":" <+> pretty b)

instance Show Builder where
  show = prettyToString

mkBuilder :: Program -> Builder
mkBuilder binds = Builder {
  bindings = binds >>= collectBindingsInBinding
}

mkSwitchFunction :: State FunctionBuilder ()
mkSwitchFunction = return ()
-}


{-
mkSwitchFunction :: Builder -> AST.Definition
mkSwitchFunction (Builder binds) = AST.GlobalDefinition (G.functionDefaults {
  G.name = strToName "mainSwitch",
  G.returnType = AST.VoidType,
  G.parameters = ([G.Parameter tagty (strToName "tag") []] , False),
  G.basicBlocks = [entrybb]
})
  where
    trapDest = strToName "trap"

    entrybb :: AST.BasicBlock
    entrybb = G.BasicBlock (strToName "entry")
                         []
                         (Do $ AST.Switch {
                            AST.operand0' = (AST.LocalReference tagty (strToName "tag")),
                            AST.defaultDest = trapDest,
                            AST.dests = dests,
                            AST.metadata'=[]
                         })

    dests :: [(Constant, AST.Name)]
    dests = map (\(i, bind) -> (i32val i, bind ^. bindingName ^. getVariable & strToName)) (zip [1..] binds)
-}


{-
-- | Create the main "switching" function.
mkSTGDefinitions :: Program -> Builder -> [AST.Definition]
mkSTGDefinitions p builder = [mkSwitchFunction builder]

-- | Tag a value
data ValueTag = ValueTagInt | ValueTagFloat deriving(Show, Enum, Bounded)

-- | Convert a 'ValueTag' to 'Int' for LLVM codegen
valueTagToInt :: ValueTag -> Int
valueTagToInt = fromEnum
-}