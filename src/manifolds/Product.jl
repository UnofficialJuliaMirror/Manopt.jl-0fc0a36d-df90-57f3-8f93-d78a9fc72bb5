#
#      Productmanifold – the manifold generated by the product of manifolds.
#
# Manopt.jl, R. Bergmann, 2018-06-26
import Base: exp, log, show

export Product, ProdPoint, ProdTVector
export distance, dot, exp, log, manifoldDimension, norm, parallelTransport
export randomMPoint, randomTVector
export validateMPoint, validateTVector
export zeroTVector
export show, getValue
@doc doc"""
    Product{M<:Manifold} <: Manifold

a product manifold $\mathcal M = \mathcal N_1\times\mathcal N_2\times\cdots\times\mathcal N_m$,
$m\in\mathbb N$,
concatinates a set of manifolds $\mathcal N_i$, $i=1,\ldots,m$, into one using
the sum of the metrics to impose a metric on this manifold. The manifold can
also be an arbitrary Array of manifolds, not necessarily only a vector.

# Abbreviation
`Prod`

# Constructor
    Product(m)

constructs a `Power` [`Manifold`](@ref) based on an array of manifolds
"""
struct Product <: Manifold
  name::String
  manifolds::Array{Manifold}
  abbreviation::String
  Product(m::Array{Manifold}) = new("Product",
    mv,prod(manifoldDimension.(m)),string("Prod(",join([mi.abbreviation for mi in m],", "),")") )
end
@doc doc"""
    ProdPoint <: MPoint

A point on the [`Product`](@ref) $\mathcal M = \mathcal N_1\times\mathcal N_2\times\cdots\times\mathcal N_m$,$m\in\mathbb N$,
represented by a vector or array of [`MPoint`](@ref)s.
"""
struct ProdPoint <: MPoint
  value::Array{MPoint}
  ProdPoint(v::Array{MPoint}) = new(v)
end
getValue(x::ProdPoint) = x.value
@doc doc"""
    ProdTVector <: TVector

A tangent vector in the product of tangent spaces of the [`Product`](@ref)
$T\mathcal M = T\mathcal N_1\times T\mathcal N_2\times\cdots\times T\mathcal N_m$,$m\in\mathbb N$,
represented by a vector or array of [`TVector`](@ref)s.
"""
struct ProdTVector <: TVector
  value::Array{TVector}
  ProdTVector(value::Array{TVector}) = new(value);
end
getValue(ξ::ProdTVector) = ξ.value

@doc doc"""
    distance(M,x,y)

computes a vectorized version of distance, and the induced norm from the metric [`dot`](@ref).
"""
distance(M::Product, x::ProdPoint, y::ProdPoint) = sqrt(sum( distance.(M.manifolds, getValue(x), getValue(y) ).^2 ))

@doc doc"""
    dot(M,x,ξ,ν)

computes the inner product as sum of the component inner products on the [`Product`](@ref).
"""
dot(M::Product, x::ProdPoint, ξ::ProdTVector, ν::ProdTVector) = sum(dot.(M.manifolds, getValue(x), getValue(ξ), getValue(ν) ));

@doc doc"""
    exp(M,x,ξ)

computes the product exponential map on the [`Product`](@ref) manifold and returns the corresponding [`ProdPoint`](@ref).
"""
exp(M::Product, x::ProdPoint,ξ::ProdTVector,t::Number=1.0) = ProdPoint( exp.(M.manifolds, getValue(x), getValue(ξ)) )

@doc doc"""
   log(M,x,y)

computes the product logarithmic map from [`PowPoint`](@ref) `x` to `y` on the
[`Product`](@ref)` `[`Manifold`](@ref) `M` and returns the corresponding
[`ProdTVector`](@ref).
"""
log(M::Product, x::ProdPoint,y::ProdPoint) = ProdTVector(log.(M.manifolds, getValue(x), getValue(y) ))

@doc doc"""
    manifoldDimension(x)

returns the (product of) dimension(s) of the [`Product`](@ref) manifold the
[`ProdPoint`](@ref) `x` belongs to.
"""
manifoldDimension(x::ProdPoint) =  prod( manifoldDimension.( getValue(x) ) )

@doc doc"""
    manifoldDimension(M)

returns the (product of) dimension(s) of the [`Product`](@ref)` `[`Manifold`](@ref) `M`.
"""
manifoldDimension(M::Product) = prod( manifoldDimension.(M.manifolds) )

@doc doc"""
    norm(M,x,ξ)

norm of the [`ProdTVector`](@ref) `ξ` induced by the metric on the manifold components
of the [`Product`](@ref)` `[`Manifold`](@ref) `M`.
"""
norm(M::Product, x::ProdPoint, ξ::ProdTVector) = sqrt( dot(M,x,ξ,ξ) )

@doc doc"""
    parallelTransport(M,x,ξ)

computes the product parallelTransport map on the [`Product`](@ref)` `[`Manifold`](@ref) `M`
and returns the corresponding [`ProdTVector`](@ref).
"""
parallelTransport(M::Product, x::ProdPoint, y::ProdPoint, ξ::ProdTVector) = ProdTVector( parallelTransport.(M.manifolds, getValue(x), getValue(y), getValue(ξ)) )

@doc doc"""
    randomMPoint(M)

generate a random point on [`Product`](@ref) `M`.
"""
randomMPoint(M::Product,options...) = ProdPoint([ randomMPoint(m, options) for m in M.manifolds ] )

@doc doc"""
    randomTVector(M,x)

generate a random tangent vector in the tangent space of the [`ProdPoint`](@ref) `x`
on [`Power`](@ref) `M`.
"""
randomTVector(M::Product,x::ProdTVector,options) = ProdTVector([
    randomTVector(m.manifolds[i], getValue(x)[i], options...)
    for i in CartesianIndices(getValue(x))
])

@doc doc"""
    typicalDistance(M)

returns the typical distance on [`Product`](@ref) `M`, which is the minimum of the internal ones.
"""
typicalDistance(M::Product) = sqrt( length(M.manifolds)*sum( typicalDistance.(M.manifolds).^2 ) );
@doc doc"""
    validateMPoint(M,x)

validate, that the [`ProdPoint`](@ref) `x` is a point on the [`Product`](@ref)
manifold `M`, i.e. that the array dimensions are correct and that all elements
are valid points on each elements manifolds
"""
function validateMPoint(M::Product, x::ProdPoint)
    if length(getValue(x)) ≠ length(M.manifolds)
        throw(ErrorException(
        " The product manifold point $x is not on $(M.name) since its number of elements ($(length(getValue(x)))) does not fit the number of manifolds ($(length(M.manifolds)))."
        ))
    end
    validateMPoint.(M.manifolds,getValue(x))
    return true
end

@doc doc"""
    validateTVector(M,x,ξ)

validate, that the [`ProdTVector`](@ref) `ξ` is a valid tangent vector to the
[`ProdPoint`](@ref) `x` on the [`Product`](@ref) `M`, i.e. that all three array
dimensions match and this validation holds elementwise.
"""
function validateTVector(M::Product, x::ProdPoint, ξ::ProdTVector)
    if (length(getValue(x)) ≠ length(getValue(ξ))) || (length(getValue(ξ)) ≠ length(M.manifolds))
        throw( ErrorException(
        "The three dimensions of the $(M.name), the point x ($(length(getValue(x)))), and the tangent vector ($(length(getValue(ξ)))) don't match."
        ))
    end
    validateTVector.(M.manifolds,getValue(x),getValue(ξ))
    return true
end
@doc doc"""
    ξ = zeroTVector(M,x)
returns a zero vector in the tangent space $T_x\mathcal M$ of the
[`ProdPoint`](@ref) $x\in\mathcal M$ on the [`Product`](@ref) manifold `M`.
"""
zeroTVector(M::Product, x::ProdPoint) = ProdTVector( zeroTVector.(M.manifolds, getValue(x) )  );
# Display
show(io::IO, M::Product) = print(io,string("The Product Manifold of [ ",
    join([m.abbreviation for m in M.manifolds])," ]"))
show(io::IO, p::ProdPoint) = print(io,string("Prod[",join(repr.( getValue(p) ),", "),"]"))
show(io::IO, ξ::ProdTVector) = print(io,String("ProdT[", join(repr.(ξ.value),", "),"]"))
