#
# Gradient Plan
#
export GradientProblem, GradientDescentOptions
export getGradient, getCost, getStepsize, getInitialStepsize

export DebugGradient, DebugGradientNorm, DebugStepsize
export RecordGradient, RecordGradientNorm, RecordStepsize
# export DirectionUpdateOptions, HessianDirectionUpdateOptions
#
# Problem
#
@doc doc"""
    GradientProblem <: Problem
specify a problem for gradient based algorithms.

# Fields
* `M`            : a manifold $\mathcal M$
* `costFunction` : a function $F\colon\mathcal M\to\mathbb R$ to minimize
* `gradient`     : the gradient $\nabla F\colon\mathcal M
  \to \mathcal T\mathcal M$ of the cost function $F$

# See also
[`steepestDescent`](@ref)
[`GradientDescentOptions`](@ref)

# """
mutable struct GradientProblem{mT <: Manifold} <: Problem
  M::mT
  costFunction::Function
  gradient::Function
end

#
# Options for subproblems
#

# abstract type DirectionUpdateOptions end
# """
#     SimpleDirectionUpdateOptions <: DirectionUpdateOptions
# A simple update rule requires no information
# """
# struct SimpleDirectionUpdateOptions <: DirectionUpdateOptions
# end
# """
#     HessianDirectionUpdateOptions
# An update rule that keeps information about the Hessian or optains these
# informations from the corresponding [`Options`](@ref)
# """
# struct HessianDirectionUpdateOptions <: DirectionUpdateOptions
# end

"""
    getGradient(p,x)

evaluate the gradient of a [`GradientProblem`](@ref)`p` at the [`MPoint`](@ref) `x`.
"""
function getGradient(p::P,x::MP) where {P <: GradientProblem{M} where M <: Manifold, MP <: MPoint}
  return p.gradient(x)
end
"""
    getCost(p,x)

evaluate the cost function `F` stored within a [`GradientProblem`](@ref) at the [`MPoint`](@ref) `x`.
"""
function getCost(p::P,x::MP) where {P <: GradientProblem{M} where M <: Manifold, MP <: MPoint}
  return p.costFunction(x)
end
#
# Options
#
"""
    GradientDescentOptions{P,L} <: Options
Describes a Gradient based descent algorithm, with

# Fields
a default value is given in brackets if a parameter can be left out in initialization.

* `x0` : an [`MPoint`](@ref) as starting point
* `stoppingCriterion` : a function s,r = @(o,iter,ξ,x,xnew) returning a stop
    indicator and a reason based on an iteration number, the gradient and the last and
    current iterates
* `retraction` : (exp) the rectraction to use
* `stepsize` : a `Function` to compute the next step size)

# See also
[`steepestDescent`](@ref)
"""
mutable struct GradientDescentOptions{P <: MPoint, T <: TVector} <: Options
    x::P where {P <: MPoint}
    ∇::T where {T <: TVector}
    stop::StoppingCriterion
    retraction::Function
    stepsize::Stepsize
    GradientDescentOptions{P,T}(
        initialX::P,
        s::StoppingCriterion,
        stepsize::Stepsize,
        retraction::Function=exp
    ) where {P <: MPoint, T <: TVector} = (
        o = new{P,typeofTVector(P)}();
        o.x = initialX;
        o.stop = s;
        o.retraction = retraction;
        o.stepsize = stepsize;
        return o
    )
end
GradientDescentOptions(x::P,stop::StoppingCriterion,s::Stepsize,retraction::Function=exp) where {P <: MPoint} = GradientDescentOptions{P,typeofTVector(P)}(x,stop,s,retraction)
getStepsize(p::P,o::O,vars...) where {P <: GradientProblem{M} where M <: Manifold, O <: GradientDescentOptions} = o.stepsze(p,o,vars...)
#
# Debugs
#

@doc doc"""
    DebugGradient <: DebugAction

debug for the gradient evaluated at the current iterate

# Constructors
    DebugGradient([long=false,p=print])

display the short (`false`) or long (`true`) default text for the gradient.

    DebugGradient(prefix[, p=print])

display the a `prefix` in front of the gradient.
"""
mutable struct DebugGradient <: DebugAction
    print::Function
    prefix::String
    DebugGradient(long::Bool=false,print::Function=print) = new(print,
        long ? "Gradient: " : "∇F(x):")
    DebugGradient(prefix::String,print::Function=print) = new(print,prefix)
end
(d::DebugGradient)(p::GradientProblem,o::GradientDescentOptions,i::Int) = d.print((i>=0) ? d.prefix*""*string(o.∇) : "")

@doc doc"""
    DebugGradientNorm <: DebugAction

debug for gradient evaluated at the current iterate.

# Constructors
    DebugGradientNorm([long=false,p=print])

display the short (`false`) or long (`true`) default text for the gradient norm.

    DebugGradientNorm(prefix[, p=print])

display the a `prefix` in front of the gradientnorm.
"""
mutable struct DebugGradientNorm <: DebugAction
    print::Function
    prefix::String
    DebugGradientNorm(long::Bool=false,print::Function=print) = new(print,
        long ? "Norm of the Gradient: " : "|∇F(x)|:")
    DebugGradientNorm(prefix::String,print::Function=print) = new(print,prefix)
end
(d::DebugGradientNorm)(p::P,o::O,i::Int) where {P <: GradientProblem, O <: GradientDescentOptions} = d.print((i>=0) ? d.prefix*"$(norm(p.M,o.x,o.∇))" : "")

@doc doc"""
    DebugStepsize <: DebugAction

debug for the current step size.

# Constructors
    DebugStepsize([long=false,p=print])

display the short (`false`) or long (`true`) default text for the step size.

    DebugStepsize(prefix[, p=print])

display the a `prefix` in front of the step size.
"""
mutable struct DebugStepsize <: DebugAction
    print::Function
    prefix::String
    DebugStepsize(long::Bool=false,print::Function=print) = new(print,
        long ? "step size:" : "s:")
    DebugStepsize(prefix::String,print::Function=print) = new(print,prefix)
end
(d::DebugStepsize)(p::P,o::O,i::Int) where {P <: GradientProblem, O <: GradientDescentOptions} = d.print((i>0) ? d.prefix*"$(getLastStepsize(p,o,i))" : "")

#
# Records
#
@doc doc"""
    RecordGradient <: RecordAction

record the gradient evaluated at the current iterate

# Constructors
    RecordGradient(ξ)

initialize the [`RecordAction`](@ref) to the corresponding type of the [`TVector`](@ref).
"""
mutable struct RecordGradient{T <: TVector} <: RecordAction
    recordedValues::Array{T,1}
    RecordGradient{T}() where {T <: MPoint} = new(Array{T,1}())
end
RecordedGradient(ξ::T) where {T <: TVector} = RecordGradient{T}()
(r::RecordGradient{T})(p::P,o::O,i::Int) where {T <: TVector, P <: GradientProblem, O <: GradientDescentOptions} = recordOrReset!(r, o.∇, i)

@doc doc"""
    RecordGradientNorm <: RecordAction

record the norm of the current gradient
"""
mutable struct RecordGradientNorm <: RecordAction
    recordedValues::Array{Float64,1}
    RecordGradientNorm() = new(Array{Float64,1}())
end
(r::RecordGradientNorm)(p::P,o::O,i::Int) where {P <: GradientProblem, O <: GradientDescentOptions} = recordOrReset!(r, norm(p.M,o.x,o.∇), i)

@doc doc"""
    RecordStepsize <: RecordAction

record the step size
"""
mutable struct RecordStepsize <: RecordAction
    recordedValues::Array{Float64,1}
    RecordStepsize() = new(Array{Float64,1}())
end
(r::RecordStepsize)(p::P,o::O,i::Int) where {P <: GradientProblem, O <: GradientDescentOptions} = recordOrReset!(r, getLastStepsize(p,o,i), i)
