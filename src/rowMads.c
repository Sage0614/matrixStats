/***************************************************************************
 Public methods:
 SEXP rowMads(SEXP x, SEXP constant, SEXP naRm, SEXP hasNA)
 SEXP colMads(SEXP x, SEXP constant, SEXP naRm, SEXP hasNA)

 Authors: Henrik Bengtsson

 Copyright Henrik Bengtsson, 2014
 **************************************************************************/
#include <Rdefines.h>
#include "types.h"

#define METHOD rowMads

#define X_TYPE 'i'
#include "rowMads_TYPE-template.h"

#define X_TYPE 'r'
#include "rowMads_TYPE-template.h"

#undef METHOD 


SEXP rowMads(SEXP x, SEXP constant, SEXP naRm, SEXP hasNA, SEXP byRow) {
  int narm, hasna, byrow;
  SEXP dim, ans;
  R_xlen_t nrow, ncol;
  double scale;

  /* Argument 'x': */
  if (!isMatrix(x))
    error("Argument 'x' must be a matrix.");

  /* Argument 'constant': */
  if (!isNumeric(constant))
    error("Argument 'constant' must be a numeric scale.");
  scale = asReal(constant);

  /* Argument 'naRm': */
  if (!isLogical(naRm))
    error("Argument 'naRm' must be a single logical.");

  if (length(naRm) != 1)
    error("Argument 'naRm' must be a single logical.");

  narm = asLogical(naRm);
  if (narm != TRUE && narm != FALSE)
    error("Argument 'naRm' must be either TRUE or FALSE.");

  /* Argument 'hasNA': */
  hasna = asLogical(hasNA);

  /* Argument 'byRow': */
  byrow = asInteger(byRow);


  /* Get dimensions of 'x'. */
  dim = getAttrib(x, R_DimSymbol);
  if (byrow) {
    nrow = INTEGER(dim)[0];
    ncol = INTEGER(dim)[1];
  } else {
    nrow = INTEGER(dim)[1];
    ncol = INTEGER(dim)[0];
  }

  /* R allocate a double vector of length 'nrow'
     Note that 'nrow' means 'ncol' if byrow=FALSE. */
  PROTECT(ans = allocVector(REALSXP, nrow));

  /* Double matrices are more common to use. */
  if (isReal(x)) {
    rowMads_Real(REAL(x), nrow, ncol, scale, narm, hasna, byrow, REAL(ans));
  } else if (isInteger(x)) {
    rowMads_Integer(INTEGER(x), nrow, ncol, scale, narm, hasna, byrow, REAL(ans));
  } else {
    UNPROTECT(1);
    error("Argument 'x' must be a numeric.");
  }

  UNPROTECT(1);

  return(ans);
} /* rowMads() */


/***************************************************************************
 HISTORY:
 2014-11-17 [HB]
 o Created from rowMedians.c.
 **************************************************************************/
