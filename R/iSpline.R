##
## R package splines2 by Wenjie Wang and Jun Yan
## Copyright (C) 2016-2025
##
## This file is part of the R package splines2.
##
## The R package splines2 is free software: You can redistribute it and/or
## modify it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or any later
## version (at your option). See the GNU General Public License at
## <https://www.gnu.org/licenses/> for details.
##
## The R package splines2 is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##

##' I-Spline Basis for Polynomial Splines
##'
##' Generates the I-spline (integral of M-spline) basis matrix for a polynomial
##' spline or the corresponding derivatives of given order.
##'
##' It is an implementation of the closed-form I-spline basis based on the
##' recursion formula given by Ramsay (1988).  The function \code{isp()} is an
##' alias of to encourage the use in a model formula.
##'
##' @inheritParams bSpline
##'
##' @param degree The degree of I-spline defined to be the degree of the
##'     associated M-spline instead of actual polynomial degree. For example,
##'     I-spline basis of degree 2 is defined as the integral of associated
##'     M-spline basis of degree 2.
##' @param intercept If \code{TRUE} by default, all of the spline basis
##'     functions are returned.  Notice that when using I-Spline for monotonic
##'     regression, \code{intercept = TRUE} should be set even when an intercept
##'     term is considered additional to the spline basis functions.
##' @param derivs A nonnegative integer specifying the order of derivatives of
##'     I-splines.
##'
##' @return A numeric matrix of \code{length(x)} rows and \code{df} columns if
##'     \code{df} is specified.  If \code{knots} are specified instead, the
##'     output matrix will consist of \code{length(knots) + degree +
##'     as.integer(intercept)} columns.  Attributes that correspond to the
##'     arguments specified are returned for usage of other functions in this
##'     package.
##'
##' @references
##' Ramsay, J. O. (1988). Monotone regression splines in action.
##' \emph{Statistical Science}, 3(4), 425--441.
##'
##' @example inst/examples/ex-iSpline.R
##'
##' @seealso
##' \code{\link{mSpline}} for M-splines;
##' \code{\link{cSpline}} for C-splines;
##'
##' @export
iSpline <- function(x, df = NULL, knots = NULL, degree = 3L,
                    intercept = TRUE, Boundary.knots = NULL,
                    derivs = 0L,
                    warn.outside = getOption("splines2.warn.outside", TRUE),
                    ...)
{
    ## check inputs
    if ((derivs <- as.integer(derivs)) < 0) {
        stop("The 'derivs' must be a nonnegative integer.")
    }
    if (derivs > 0) {
        return(mSpline(x = x,
                       df = df,
                       knots = knots,
                       degree = degree,
                       intercept = intercept,
                       Boundary.knots = Boundary.knots,
                       periodic = FALSE,
                       derivs = derivs - 1L,
                       integral = FALSE))
    }
    ## else I-Spline basis
    if ((degree <- as.integer(degree)) < 0)
        stop("The 'degree' must be a nonnegative integer.")
    if (is.null(df)) {
        df <- 0L
    } else {
        df <- as.integer(df)
        if (df < 0) {
            stop("The 'df' must be a nonnegative integer.")
        }
    }
    knots <- null2num0(knots)
    Boundary.knots <- null2num0(Boundary.knots)
    ## take care of possible NA's in `x`
    nax <- is.na(x)
    if (all(nax)) {
        stop("The 'x' cannot be all NA's!")
    }
    ## remove NA's in x
    xx <- if (nas <- any(nax)) {
              x[! nax]
          } else {
              x
          }
    ## call the engine function
    out <- rcpp_iSpline(
        x = xx,
        df = df,
        degree = degree,
        internal_knots = knots,
        boundary_knots = Boundary.knots,
        derivs = derivs,
        integral = FALSE,
        complete_basis = intercept
    )
    ## throw warning if any x is outside of the boundary
    b_knots <- attr(out, "Boundary.knots")
    if (warn.outside && any((xx < b_knots[1L]) | (xx > b_knots[2L]))) {
        warning(wrapMessages(
            "Some 'x' values beyond boundary knots",
            "may cause ill-conditioned basis functions."
        ))
    }
    ## keep NA's as is
    if (nas) {
        nmat <- matrix(NA, length(nax), ncol(out))
        nmat[! nax, ] <- out
        saved_attr <- attributes(out)
        saved_attr$dim[1] <- length(nax)
        out <- nmat
        attributes(out) <- saved_attr
        attr(out, "x") <- x
    }
    ## add dimnames for consistency
    name_x <- names(x)
    if (! is.null(name_x)) {
        row.names(out) <- name_x
    }
    ## add class
    class(out) <- c("ISpline", "splines2", "matrix")
    out
}

##' @rdname iSpline
##' @export
isp <- iSpline
