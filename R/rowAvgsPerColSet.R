#' Applies a row-by-row (column-by-column) averaging function to equally-sized
#' subsets of matrix columns (rows)
#'
#' Applies a row-by-row (column-by-column) averaging function to equally-sized
#' subsets of matrix columns (rows).  Each subset is averaged independently of
#' the others.
#'
#' If argument \code{S} is a single column vector with indices \code{1:N}, then
#' \code{rowAvgsPerColSet(X, S = S, FUN = rowMeans)} gives the same result as
#' \code{rowMeans(X)}.  Analogously, for \code{rowAvgsPerColSet()}.
#'
#' @param X A \code{\link[base]{numeric}} NxM \code{\link[base]{matrix}}.
#'
#' @param W An optional \code{\link[base]{numeric}} NxM
#' \code{\link[base]{matrix}} of weights.
#'
#' @param rows,cols A \code{\link[base]{vector}} indicating subset of rows
#' (and/or columns) to operate over. If \code{\link[base]{NULL}}, no subsetting
#' is done.
#'
#' @param S An \code{\link[base]{integer}} KxJ \code{\link[base]{matrix}}
#' specifying the J subsets.  Each column holds K column (row) indices for the
#' corresponding subset.
#'
#' @param FUN The row-by-row (column-by-column) \code{\link[base]{function}}
#' used to average over each subset of \code{X}.  This function must accept a
#' \code{\link[base]{numeric}} NxK (KxM) \code{\link[base]{matrix}} and the
#' \code{\link[base]{logical}} argument \code{na.rm} (which is automatically
#' set), and return a \code{\link[base]{numeric}} \code{\link[base]{vector}} of
#' length N (M).
#'
#' @param ... Additional arguments passed to then \code{FUN}
#' \code{\link[base]{function}}.
#'
#' @param tFUN If \code{\link[base:logical]{TRUE}}, the NxK (KxM)
#' \code{\link[base]{matrix}} passed to \code{FUN()} is transposed first.
#'
#' @return Returns a \code{\link[base]{numeric}} JxN (MxJ)
#' \code{\link[base]{matrix}}, where row names equal \code{rownames(X)}
#' (\code{colnames(S)}) and column names \code{colnames(S)}
#' (\code{colnames(X)}).
#'
#' @example incl/rowAvgsPerColSet.R
#'
#' @author Henrik Bengtsson
#' @keywords internal utilities
#' @export
rowAvgsPerColSet <- function(X, W = NULL, rows = NULL, S,
                             FUN = rowMeans, ..., tFUN = FALSE) {
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Validate arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Argument 'X':
  if (!is.matrix(X)) {
    stop("Argument 'X' is not a matrix: ", class(X)[1L])
  }
  dimX <- dim(X)

  # Argument 'W':
  hasW <- !is.null(W)
  if (hasW) {
    if (!is.matrix(W)) {
      stop("Argument 'W' is not a matrix: ", class(W)[1L])
    }
    if (any(dim(W) != dimX)) {
      stop("Argument 'W' does not have the same dimension as 'X': ",
           paste(dim(W), collapse = "x"), " != ", paste(dimX, collapse = "x"))
    }
    if (!is.numeric(W)) {
      stop("Argument 'W' is not numeric: ", mode(W))
    }
  }

  # Argument 'S':
  if (!is.matrix(S)) {
    stop("Argument 'S' is not a matrix: ", class(S)[1L])
  }
  nbrOfSets <- ncol(S)
  setNames <- colnames(S)

  # Argument 'FUN':
  if (!is.function(FUN)) {
    stop("Argument 'FUN' is not a function: ", mode(S))
  }

  # Apply subset
  if (!is.null(rows)) {
    X <- X[rows, , drop = FALSE]
    if (hasW) W <- W[rows, , drop = FALSE]
    dimX <- dim(X)
  }

  # Argument 'tFUN':
  tFUN <- as.logical(tFUN)


  # Check if missing values have to be excluded while averaging
  na.rm <- (anyMissing(X) || anyMissing(S))

  # Record names of dimension
  rownamesX <- rownames(X)
  dimnames(X) <- NULL

  # Average in sets of columns of X.
  Z <- apply(S, MARGIN = 2L, FUN = function(jj) {
    # Extract set of columns from X
    jj <- jj[is.finite(jj)]
    Zjj <- X[, jj, drop = FALSE]
    jj <- NULL  # Not needed anymore

    if (tFUN) {
      Zjj <- t(Zjj)
    }

    # Average by weights
    if (hasW) {
      Wjj <- W[, jj, drop = FALSE]
      Zjj <- FUN(Zjj, W = Wjj, ..., na.rm = na.rm)
      Wjj <- NULL  # Not needed anymore
    } else {
      Zjj <- FUN(Zjj, ..., na.rm = na.rm)
    }

    # Sanity check
    stopifnot(length(Zjj) == dimX[1L])

    # Return set average
    Zjj
  })

  # apply() drops 2nd dimension if nrow(X) <= 1 (and FUN returns a vector of
  # length nrow(X) as it should), cf. ?apply
  if (!is.matrix(Z)) {
    stopifnot(dimX[1] <= 1L)
    dim(Z) <- c(length(Z), nbrOfSets)
  }

  # Sanity check
  stopifnot(dim(Z) == c(dimX[1L], nbrOfSets))

  # Set names
  rownames(Z) <- rownamesX
  colnames(Z) <- setNames

  Z
}

#' @rdname rowAvgsPerColSet
#' @export
colAvgsPerRowSet <- function(X, W = NULL, cols = NULL, S,
                             FUN = colMeans, ..., tFUN = FALSE) {
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Validate arguments
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Argument 'X':
  if (!is.matrix(X)) {
    stop("Argument 'X' is not a matrix: ", class(X)[1L])
  }

  # Argument 'W':

  # Argument 'S':
  if (!is.matrix(S)) {
    stop("Argument 'S' is not a matrix: ", class(S)[1L])
  }

  # Argument 'FUN':
  if (!is.function(FUN)) {
    stop("Argument 'FUN' is not a function: ", mode(S))
  }

  # Apply subset
  if (!is.null(cols)) {
    X <- X[, cols, drop = FALSE]
    if (is.null(W)) W <- W[, cols, drop = FALSE]
  }

  # Argument 'tFUN':
  tFUN <- as.logical(tFUN)


  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Transpose
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  tX <- t(X)
  if (is.null(W)) {
    tW <- NULL
  } else {
    tW <- t(W)
  }

  # ...
  tZ <- rowAvgsPerColSet(X = tX, W = tW, S = S, FUN = FUN, ..., tFUN = !tFUN)
  tX <- tW <- NULL  # Not needed anymore

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Transpose back
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  Z <- t(tZ)
  tZ <- NULL  # Not needed anymore

  Z
}
