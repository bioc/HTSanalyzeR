.onLoad<-function(libname, pkgname) {
	packageStartupMessage(
"/////////////////////////////////////////////////////////////////////////////\n
//------------------    Thanks for using HTSanalyzeR    -------------------//\n 
//------------please use function changes() to see new changes-------------//\n
//------------please report any bug to xinwang2hms@gmail.com---------------//\n
/////////////////////////////////////////////////////////////////////////////\n", 
appendLF=FALSE)
}
changes<-function() {
cat(
"//changes in v2.13.1 (Sep 29, 2013)\n
- Bug corrected for GSEA. The bug was that the size of
  gene set was computed before filtering out genes that
  are not in the universe. \n")
}
##//changes in v2.13.1 (Sep 12, 2013)\n
##- Change the dependency on igraph0 to igraph, as requested \n
##//changes in v2.9.5\n
##- Corrected a bug in function hyperGeoTest to avoid significant p-values for 
##zero observed hit.\n
##//changes in v2.9.4\n
##- Correct a contradiction in annotationConvertor. Now it can convert between 
##entrez genes and non-entrez genes.\n
##//changes in v2.9.3\n
##- The dependency of igraph was changed to igraph0 to adapt to the change in 
##  BioNet.\n
##//changes in v2.9.2\n
##- Gene set overrepresentation and enrichment analysis can run independently 
##  using the S4 method 'analyze' by specifying argument 'doGSOA' (for 
##  hypergeometric test based overrepresentation analysis) and 'doGSEA' (for 
##  GSEA). More details in ?analyze.
##- One bug corrected for function 'analyzeGeneSetCollection' when calculating the 
##  overlap of significant gene sets in both GSEA and HyperGeo.\n
##//changes in v2.9.1\n
##- dependent pakcages BioNet, cellHTS2, AnnotationDbi, biomaRt, RankProd were 
##  moved from 'depend' to 'import' field in DESCRIPTION
##- the problem of no global binding for 'org.Rn.egGO2EG' in function 'GOGeneSets' 
##  and 'KeggGeneSets' was resolved
##- default download link of the BioGRID database in function 'biogridDataDownload' 
##  was updated to version 3.1.89 (tested on Jun 11, 2012)\n


.onAttach <- function(libname, pkgname) {
    msg <- sprintf(
        "Package '%s' is deprecated and will be removed from Bioconductor
         version %s", pkgname, "3.11")
    .Deprecated(msg=paste(strwrap(msg, exdent=2), collapse="\n"))
}

