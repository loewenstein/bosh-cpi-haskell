module CPI.Base.Response(
    Response(..)
  , ResultType(..)
  , createSuccess
  , createFailure
) where

import           CPI.Base.Errors

import           Control.Exception.Safe
import           Data.Aeson.Types
import           Data.Semigroup
import           Data.Text              (Text)
import qualified Data.Text              as Text

data Response =  Response {
    responseResult :: Maybe ResultType
  , responseError  :: Maybe CpiError
} deriving (Eq, Show)

instance ToJSON Response where
    toJSON (Response responseResult responseError) =
        object ["result" .= responseResult, "error" .= responseError, "log" .= (""::Text)]
    toEncoding (Response responseResult responseError) =
        pairs ("result" .= responseResult <> "error" .= responseError <> "log" .= (""::Text))

data ResultType = Id Text | Boolean Bool deriving (Eq, Show)

instance ToJSON ResultType where
    toJSON (Id text)      = String text
    toJSON (Boolean text) = Bool text

createSuccess :: ResultType -> Response
createSuccess result = Response {
      responseResult = Just result
    , responseError = Nothing
  }

createFailure :: SomeException -> Response
createFailure e = case fromException e of
  (Just (CloudError message)) -> Response {
      responseResult = Nothing
    , responseError = Just CpiError {
          errorType = "Bosh::Clouds::CloudError"
        , errorMessage = message
        , okToRetry = False
      }
  }
  (Just (NotImplemented message)) -> Response {
      responseResult = Nothing
    , responseError = Just CpiError {
          errorType = "Bosh::Clouds::NotImplemented"
        , errorMessage = message
        , okToRetry = False
      }
  }
  _ -> Response {
      responseResult = Nothing
    , responseError = Just CpiError {
          errorType = "Bosh::Clouds::CloudError"
        , errorMessage = "Unknown error: '" <> (Text.pack.show) e <> "'"
        , okToRetry = False
      }
  }

data CpiError = CpiError {
    errorType    :: Text
  , errorMessage :: Text
  , okToRetry    :: Bool
} deriving (Eq, Show)

instance ToJSON CpiError where
    toJSON (CpiError errorType errorMessage okToRetry) =
        object ["type" .= errorType, "message" .= errorMessage, "ok_to_retry" .= okToRetry]
    toEncoding (CpiError errorType errorMessage okToRetry) =
        pairs ("type" .= errorType <> "message" .= errorMessage <> "ok_to_retry" .= okToRetry)
