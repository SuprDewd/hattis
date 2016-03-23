module Settings.Parser (Setting(..), SettingsStorage) where
import Control.Arrow
import Control.Monad
import Data.Char
import Data.Maybe
import Error
import Settings.Lexer
import System.Directory
import Text.ParserCombinators.Parsec
import qualified Data.List as L
import qualified Data.Map.Strict as M

type Schema = [(Setting, String -> Bool)]
type SettingsStorage = M.Map String (M.Map String String)

data Setting
    = Username
    | Token         
    | LoginUrl     
    | SubmissionUrl
    deriving Show

class KeyVal a where
    key :: a -> String
    val :: a -> String

instance KeyVal Setting where
    key Username      = "user"
    key Token         = "user"
    key LoginUrl      = "kattis"
    key SubmissionUrl = "kattis"

    val Username      = "username"
    val Token         = "token"
    val LoginUrl      = "loginurl"
    val SubmissionUrl = "submissionurl"


valid :: Schema
valid = let f fun = all (==True) . map fun in
        [(Username, f isAlpha), (Token, f isHexDigit),
         (LoginUrl, f isAscii), (SubmissionUrl, f isAscii)]

verify :: SettingsStorage -> Schema -> Either KattisError SettingsStorage
verify sett = g . map (\(s,_) -> ErroneousSettings (key s) (val s))
                     . filter (not . snd) . map apply 
        where apply (a,b) = (a, f $ b <$> getKey sett a)
              f = fromMaybe False
              g [] = Right sett
              g (x:_) = Left x

structure :: [Token] -> SettingsStorage 
structure = M.fromList . map (second M.fromList . prepareMap) . L.groupBy issec  
        where issec (TSection _) (TKeyVal _ _) = True
              issec _ _ = False

prepareMap (TSection s:xs) = (s,map tuple xs)
        where tuple (TKeyVal a b) = (a,b)

-- TODO: Move to re-exporting module
lexrc :: String -> Either KattisError SettingsStorage
lexrc x = structure <$> tokenize x 

--test = ((`verify` valid) =<<) . lexrc <$> readFile "kattisrc"

getKey :: SettingsStorage -> Setting -> Maybe String
getKey a b = (val b `M.lookup`) =<< (key b `M.lookup` a)
