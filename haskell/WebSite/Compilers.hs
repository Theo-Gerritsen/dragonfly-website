{-# LANGUAGE OverloadedStrings #-}
module WebSite.Compilers (
  readScholmd,
  writeScholmd,
  scholmdCompiler,
  imageCredits,
) where

import Data.Default (def)
import Data.Monoid ((<>))

import Hakyll

import Text.Pandoc.Definition (Pandoc)

import WebSite.Config
import WebSite.DomUtil.Images

readScholmd :: Compiler (Item Pandoc)
readScholmd = do
    csl <- load cslIdentifier
    bib <- load bibIdentifier
    readPandocBiblio def csl bib =<< getResourceString

writeScholmd :: Item Pandoc -> Compiler (Item String)
writeScholmd = return . writePandocWith htm5Writer

scholmdCompiler :: Compiler (Item String)
scholmdCompiler = readScholmd >>= writeScholmd

-- FIXME: imgMeta is not used. Should it be?
imageCredits :: [Item String] -> Item String -> Compiler (Item String)
imageCredits imgMeta = return . fmap processFigures


