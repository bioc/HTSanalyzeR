##This function takes a list of gene set collections, a named phenotype 
##vector (with names(phenotype vector)=GeneUniverse), a vector of hits 
##(names only) and returns the results of hypergeometric and gene set 
##enrichment analysis for all of the gene set collections (with multiple 
##hypothesis testing correction).
analyzeGeneSetCollections <- function(listOfGeneSetCollections, geneList, 
	hits, pAdjustMethod = "BH", pValueCutoff = 0.05, nPermutations=1000, 
	minGeneSetSize=15, exponent=1, verbose=TRUE, doGSOA=TRUE, doGSEA=TRUE) {
	##check arguments
	if((!doGSOA)&&(!doGSEA))
		stop("Please choose to perform hypergeometric tests and/or GSEA by specifying 'doGSOA' and 'doGSEA'!\n")
	if(doGSOA || doGSEA) {
		paraCheck("gscs",listOfGeneSetCollections)
		paraCheck("genelist",geneList)	
		paraCheck("pAdjustMethod",pAdjustMethod)
		paraCheck("pValueCutoff",pValueCutoff)
		paraCheck("minGeneSetSize",minGeneSetSize)
		paraCheck("verbose",verbose)
	}
	if(doGSOA) {
		paraCheck("hits",hits)
	}
	if(doGSEA) {
		paraCheck("nPermutations",nPermutations)
		paraCheck("exponent",exponent)
	}
	numGeneSetCollections<-length(listOfGeneSetCollections)

	##GSEA.results.list <- vector("list", (numGeneSetCollections))
	##filter 'istOfGeneSetCollections' by 'minGeneSetSize'
	max.size<-0
	for(l in 1:numGeneSetCollections) {
		gs.size <- unlist(
			lapply(
				lapply(
					listOfGeneSetCollections[[l]], intersect, 
					y = names(geneList)
				),
				length
			)
		)
		max.size <- max(max(gs.size), max.size)
		gs.id <- which(gs.size >= minGeneSetSize)
		n.gs.discarded <- length(listOfGeneSetCollections[[l]]) - 
			length(gs.id)
		listOfGeneSetCollections[[l]] <- 
			listOfGeneSetCollections[[l]][gs.id]
		##output information about filtering of gene set collections
		if(verbose && n.gs.discarded > 0)
			cat(paste("--", n.gs.discarded, " gene sets don't have >= ", 
				minGeneSetSize, " overlapped genes with universe in gene",
				" set collection named ", names(listOfGeneSetCollections)[l], 
				"!\n",sep=""))
	}
	##stop when no gene set passes the size requirement
	if(all(unlist(lapply(listOfGeneSetCollections,length))==0))
		stop(paste("No gene set has >= ",minGeneSetSize, " overlapped ", 
				"genes with universe!\n The largest number of overlapped ",
				"genes between gene sets and universe is: ", max.size, sep=""))
	result.names<-names(listOfGeneSetCollections)
	######################
	###Hypergeometric test
	######################
	if(doGSOA) {
		HGTresults<-list()
		cat("-Performing hypergeometric analysis ...\n")

		for(i in 1 : length(listOfGeneSetCollections)) {
			if(verbose) {
				cat("--For", names(listOfGeneSetCollections)[i], "\n")
			}
			if(length(listOfGeneSetCollections[[i]]) > 0)
				HGTresults[[i]] <- multiHyperGeoTest(
					listOfGeneSetCollections[[i]], universe=names(geneList), 
					hits = hits, minGeneSetSize = minGeneSetSize, 
					pAdjustMethod = pAdjustMethod, verbose = verbose)
			else {
				HGTresults[[i]] <- matrix(, nrow=0, ncol=7)
				colnames(HGTresults[[i]]) <- c("Universe Size", 
					"Gene Set Size", "Total Hits", "Expected Hits", 
					"Observed Hits", "Pvalue", "Adjusted.Pvalue")
			}
		}
		pvals <- NULL
		##loop combines pvalues from all gene set collections' results
		##into one vector for multiple hypothesis testing pvalue adjustement
		sapply(1:numGeneSetCollections, function(i) {
			if(nrow(HGTresults[[i]])>0) {
				pv<-HGTresults[[i]][,"Pvalue"]
				names(pv)<-rownames(HGTresults[[i]])
				pvals<<-c(pvals,pv)	
			}
		})
		##Adjustment of pvalues
		HGTpvals<-p.adjust(pvals,method=pAdjustMethod)
		sapply(1:numGeneSetCollections, function(i) {
			if(nrow(HGTresults[[i]])>0) {
			ind<-match(rownames(HGTresults[[i]]),names(HGTpvals))
			Adjusted.Pvalue<-HGTpvals[ind]
			#HGTresults[[i]]<-cbind(HGTresults[[i]],Adjusted.Pvalue)
			HGTresults[[i]][,"Adjusted.Pvalue"]<<-Adjusted.Pvalue
			}
		})
		
		names(HGTresults)<-result.names
		cat("-Hypergeometric analysis complete\n\n")	
		
		##identify gene set collections with hypergeometric test 
		##pvalues < pValueCutoff
		sign.hgt<-lapply(HGTresults, function(x) {
			if(nrow(x)>0) {
				a<-which(x[,"Pvalue"]<pValueCutoff)
				x<-x[a,,drop=FALSE]
				if(length(a)>1) {
					x<-x[order(x[,"Pvalue"]),,drop=FALSE]
				}
				return(x)
			}
		})
		##identify gene set collections with hypergeometric test adjusted 
		##pvalues < pValueCutoff
		sign.hgt.adj<-lapply(HGTresults, function(x) {
			if(nrow(x)>0) {
				a<-which(x[,"Adjusted.Pvalue"]<pValueCutoff)
				x<-x[a,,drop=FALSE]
				if (length(a)>1) {
					x<-x[order(x[,"Adjusted.Pvalue"]),,drop=FALSE]
				}
				return(x)
			}
		})	
	} else {
		HGTresults=NULL
	}
	######################
	###GSEA
	######################
	if(doGSEA) {
		GSEA.results.list <- list()
		cat("-Performing gene set enrichment analysis ...\n")
		##Calculate enrichment scores for all gene sets in all collections
		test.collection<-list()
		sapply(1:length(listOfGeneSetCollections), function(i) {
				if(verbose) {
					cat("--For", names(listOfGeneSetCollections)[i], "\n")
				}
				if(length(listOfGeneSetCollections[[i]]) > 0)
					test.collection[[i]] <<- collectionGsea(
						listOfGeneSetCollections[[i]], 
						geneList=geneList,exponent=exponent,
						nPermutations=nPermutations, 
						minGeneSetSize=minGeneSetSize,verbose=verbose)
				else {
					test.collection[[i]]<<-list(Observed.scores=NULL, 
						Permutation.scores=NULL)
				}			
			}
		)
		##Combine observed and permutation scores for all gene set 
		##collections so that fdr and pvalue functions can be performed on 
		##the entire set of results
		obs.scores<-NULL
		prm.scores<-NULL
		sapply(1:numGeneSetCollections, function(i) {
				obs.scores <<- c(obs.scores, 
					test.collection[[i]]$Observed.scores)
				prm.scores <<- rbind(prm.scores, 
					test.collection[[i]]$Permutation.scores)
			}
		)
		if(length(obs.scores) > 0) {
			total.test.collect <- list("Observed.scores" = obs.scores, 
				"Permutation.scores" = prm.scores)		
			test.FDR.collection <- FDRcollectionGsea(
				permScores = total.test.collect$Permutation.scores,
				dataScores = total.test.collect$Observed.scores)
			test.pvalues.collection <- permutationPvalueCollectionGsea(
				permScores = total.test.collect$Permutation.scores,
				dataScores = total.test.collect$Observed.scores)		
			gsea.adjust.pval <- p.adjust(test.pvalues.collection, 
				method = pAdjustMethod)
			test.GSEA.results <- cbind(total.test.collect$Observed.scores, 
				test.pvalues.collection, gsea.adjust.pval, test.FDR.collection)			
			colnames(test.GSEA.results) <- c("Observed.score", "Pvalue", 
				"Adjusted.Pvalue", "FDR")

			##Extract results dataframe for each gene set collection and 
			##orders them by adjusted p-value
			sapply(1 : numGeneSetCollections, function(i) {
					if(!is.null(test.collection[[i]])) {
						match.ind <- match(names(listOfGeneSetCollections[[i]]),
							rownames(test.GSEA.results))
						match.ind <- match.ind[which(!is.na(match.ind))]
						GSEA.res.mat <- test.GSEA.results[match.ind, , drop=FALSE]
						GSEA.res.mat <- GSEA.res.mat[order(
							GSEA.res.mat[, "Adjusted.Pvalue"]), , drop=FALSE]
						GSEA.results.list[[i]] <<- GSEA.res.mat
					}
				}
			)	

			names(GSEA.results.list) <- result.names
		} else {
			##GSEA.results.list <- vector("list", (numGeneSetCollections))
			sapply(1 : numGeneSetCollections, function(i) {
					GSEA.results.list[[i]] <<- matrix(, nrow=0, ncol=4)
					colnames(GSEA.results.list[[i]]) <<- c("Observed.score", 
						"Pvalue", "Adjusted.Pvalue", "FDR")
				}
			)
		}	
		##identify gene set collections with GSEA pvalues < pValueCutoff
		sign.gsea<-lapply(GSEA.results.list, function(x) {
			if(nrow(x)>0) {
				a<-which(x[,"Pvalue"]<pValueCutoff)
				x<-x[a,,drop=FALSE]
				if (length(a)>1) {
					x<-x[order(x[,"Pvalue"]),,drop=FALSE]
				}
				return(x)
			}
		})
		##identify gene set collections with adjusted GSEA pvalues < pValueCutoff	
		sign.gsea.adj<-lapply(GSEA.results.list, function(x) {
			if(nrow(x)>0) {
				a<-which(x[,"Adjusted.Pvalue"]<=pValueCutoff)
				x<-x[a,,drop=FALSE]
				if(length(a)>1) {
					x<-x[order(x[,"Adjusted.Pvalue"]),,drop=FALSE]
				}
				return(x)
			}
		})
	} else {
		GSEA.results.list=NULL
	}
	if(doGSOA && doGSEA) {
		overlap<-list()
		overlap.adj<-list()
		##identify gene set collections with significant pvalues and/or 
		##adjusted pvalues from both GSEA and hypergeometric testing
		sapply(1:numGeneSetCollections, function(i) {
				a1 <- intersect(rownames(sign.gsea[[i]]), 
					rownames(sign.hgt[[i]]))
				a2 <- intersect(rownames(sign.gsea.adj[[i]]), 
					rownames(sign.hgt.adj[[i]]))
				Hypergeometric.Pvalue <- 
					HGTresults[[i]][a1, "Pvalue", drop=FALSE]
				Hypergeometric.Adj.Pvalue <- 
					HGTresults[[i]][a2, "Adjusted.Pvalue", drop=FALSE]		
				GSEA.Pvalue <- 
					GSEA.results.list[[i]][a1, "Pvalue", drop=FALSE]
				GSEA.Adj.Pvalue <- 
					GSEA.results.list[[i]][a2, "Adjusted.Pvalue", drop=FALSE]		
				overlap[[i]] <<- cbind(Hypergeometric.Pvalue, GSEA.Pvalue)
				colnames(overlap[[i]])<<-c("HyperGeo.Pvalue","GSEA.Pvalue")
				overlap.adj[[i]] <<- 
					cbind(Hypergeometric.Adj.Pvalue, GSEA.Adj.Pvalue)
				colnames(overlap.adj[[i]])<<-c("HyperGeo.Adj.Pvalue","GSEA.Adj.Pvalue")
			}
		)
		names(overlap) <- result.names	
		names(overlap.adj) <- result.names	
	} else {
		overlap=NULL
		overlap.adj=NULL
	}

	cat("-Gene set enrichment analysis complete \n")
	final.results <- list("HyperGeo.results" = HGTresults, 
		"GSEA.results" = GSEA.results.list, "Sig.pvals.in.both" = overlap,
		"Sig.adj.pvals.in.both" = overlap.adj)
	return(final.results)
}
