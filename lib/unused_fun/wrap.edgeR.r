require('edgeR')

# x is samples x features
# y is 2-group factor
# returns p-values
"exact.test.edgeR" <- function(x, y, use.fdr=TRUE,
		norm.factor.method=c('none','RLE')[1],
		include.foldchange=FALSE){
	require('edgeR')
	
	y <- as.factor(y)
	if(length(levels(y)) != 2) stop('y must be a 2-level factor')

	d <- DGEList(count=t(x), group=y)
	d <- calcNormFactors(d, method=norm.factor.method)
 	d <- estimateCommonDisp(d)
 	d <- estimateTagwiseDisp(d)
	et <- exactTest(d)
	
	return(et)
}

# x is samples x features
# y is 2-group factor
# returns p-values
"exact.test.edgeR.covariates" <- function(x, y, covariates=NULL,
		use.fdr=TRUE, norm.factor.method=c('none','RLE')[1],
		estimate.trended.disp=FALSE,
		verbose=TRUE){

	require('edgeR')

	# drop NA's
	ix <- !is.na(y)
	x <- x[ix,]
	y <- y[ix]
	covariates <- covariates[ix,]

	# drop constant covariates
	covariates <- covariates[,apply(covariates,2,function(xx) length(unique(xx)) > 1)]

	if(verbose) cat('Making DGEList...\n')
	d <- DGEList(count=t(x), group=y)
	if(verbose) cat('calcNormFactors...\n')
	d <- calcNormFactors(d,)
	if(!is.null(covariates)){
		covariates <- as.data.frame(covariates)
		covariates <- cbind(y, covariates)
		covariates <- droplevels(covariates)
		design <- model.matrix(~ ., data=covariates)		
	} else {
		design <- model.matrix(~y)
	}

	if(verbose) cat('estimate common dispersion...\n')
	d <- estimateGLMCommonDisp(d, design)
	if(estimate.trended.disp){
		if(verbose) cat('estimate trended dispersion...\n')
		d <- estimateGLMTrendedDisp(d, design)
	}
	if(verbose) cat('estimate tagwise dispersion...\n')
	d <- estimateGLMTagwiseDisp(d,design)
	
	if(verbose) cat('fit glm...\n')
	fit <- glmFit(d,design)
	if(verbose) cat('likelihood ratio test...\n')
	lrt <- glmLRT(fit,coef=2)
	
	return(lrt)
}


# runs set of differential "expression" tests
# x is a sample x obs count matrix, e.g. taxa, otus
#
# test.list is a named list of tests, each of the form:
#    list(ix=<logical indices of samples to test>,
#         group=<grouping vector, factor with 2 levels>,
#         covariate.names=<list of map column headers, can be omitted>)
# map must be included if any tests have covariate.names listed
#
"run.DGE.tests" <- function(x, test.list, map=NULL, verbose=FALSE){
	res <- list()

	for(j in seq_along(test.list)){
		ix <- test.list[[j]]$ix
		y <- test.list[[j]]$group
		covariate.names <- test.list[[j]]$covariate.names
		if(is.null(covariate.names)){	
			res[[names(test.list)[j]]] <- exact.test.edgeR(x[ix,], y[ix])
		} else {
			res[[names(test.list)[j]]] <- 
					exact.test.edgeR.covariates(x[ix,],y[ix],
						covariates = map[ix,covariate.names])
		}
		if(verbose){
			cat('\n\n',names(test.list)[j],'\n')
			print(topTags(res[[names(test.list)[j]]]))
		}
	}
	return(res)
}

