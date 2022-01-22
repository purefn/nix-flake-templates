{-# LANGUAGE OverloadedStrings #-}

import           Network.HTTP.Types             ( status200 )
import           Network.HTTP.Types.Header      ( hContentType )
import           Network.Wai                    ( Application
                                                , responseLBS
                                                )
import           Network.Wai.Handler.Warp       ( run )
import           System.Environment             ( lookupEnv )

main :: IO ()
main = do
  port <- maybe 8080 read <$> lookupEnv "PORT"
  putStrLn $ "Listening on port " ++ show port
  run port app

app :: Application
app req respond =
  respond
    . responseLBS status200 [(hContentType, "text/plain")]
    $ "Hello world!"
