{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Main where

import OddJobs.Job (Job(..), ConcurrencyControl(..), Config(..), throwParsePayload,
                    createJob, JobRunnerName(..), Status(..))
import OddJobs.ConfigBuilder (mkConfig, withConnectionPool, defaultTimedLogger, defaultLogStr, defaultJobType)
import OddJobs.Cli (defaultMain)

-- Note: It is not necessary to use fast-logger. You can use any logging library
-- that can give you a logging function in the IO monad.
import System.Log.FastLogger(withTimedFastLogger, LogType'(..), defaultBufSize)
import System.Log.FastLogger.Date (newTimeCache, simpleTimeFormat)

import Data.Text (Text, pack)
import Data.Aeson as Aeson
import GHC.Generics
import Data.Time.Clock

-- This example is using these functions to introduce an artificial delay of a
-- few seconds in one of the jobs. Otherwise it is not really needed.
import OddJobs.Types (delaySeconds, Seconds(..))

import Database.PostgreSQL.Simple.Internal

import qualified MyLib (someFunc)


data MyJob = SendWelcomeEmail Int 
  | SendPasswordResetEmail Text 
  | SetupSampleData Int 
  deriving (Eq, Show, Generic, ToJSON, FromJSON)

myJobRunner :: Job -> IO ()
myJobRunner job = do
  j <- throwParsePayload job
  print "Job Payload"
  print j 
  case j of  
    SendWelcomeEmail 10 -> do 
      putStrLn $ "This should call the function that actually sends the welcome email. " ++ "\nWe are purposely waiting 60 seconds before completing this job so that graceful shutdown can be demonstrated."
      delaySeconds (Seconds 60)
      putStrLn "60 second wait is now over..."
    SendPasswordResetEmail tkn ->
      putStrLn "This should call the function that actually sends the password-reset email"
    SetupSampleData 10 -> do
      Prelude.error "User onboarding is incomplete"
      putStrLn "This should call the function that actually sets up sample data in a newly registered user's account"
    _ -> do 
      print j
      print "default"
main :: IO ()
main = do
  putStrLn "Hello, Haskell!"
  MyLib.someFunc
  tempsCourrant <- getCurrentTime 
  let connInf = ConnectInfo "localhost" 5432 "postgres" "Ange2310!!" "jobs_test" 
      myJobsTable = "jobs_test"
      myjob = Job 1 tempsCourrant tempsCourrant tempsCourrant OddJobs.Job.Success (toJSON $ SendWelcomeEmail 10) Nothing 5 (Just tempsCourrant) (Just $ JobRunnerName $ pack "JOBS_TEST")
  conn <- connect  connInf 

  --job <- createJob conn myJobsTable (SendWelcomeEmail 10)
  --myJobRunner myjob 
  --startJobMonitor :: (Config -> IO ()) -> IO ()

  defaultMain startJobMonitor
    where
      startJobMonitor callback =
        withConnectionPool (Left "dbname=jobs_test user=postgres password=Ange2310!! host=localhost") $ \dbPool -> do
          tcache <- newTimeCache simpleTimeFormat
          withTimedFastLogger tcache (LogFileNoRotate "oddjobs.log" defaultBufSize) $ \logger -> do
            let jobLogger = defaultTimedLogger logger (defaultLogStr defaultJobType)
                cfg = mkConfig jobLogger "jobs" dbPool (MaxConcurrentJobs 50) myJobRunner Prelude.id
            callback cfg


