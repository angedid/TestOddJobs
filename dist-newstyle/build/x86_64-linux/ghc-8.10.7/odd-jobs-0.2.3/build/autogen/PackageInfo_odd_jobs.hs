{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_odd_jobs (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "odd_jobs"
version :: Version
version = Version [0,2,3] []

synopsis :: String
synopsis = "A full-featured PostgreSQL-backed job queue (with an admin UI)"
copyright :: String
copyright = "2016-2020 Saurabh Nanda"
homepage :: String
homepage = "https://www.haskelltutorials.com/odd-jobs"
