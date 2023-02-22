using Pkg; Pkg.activate(".."); Pkg.instantiate()
using RxInfer,Distributions,Random,LinearAlgebra,OhMyREPL, ReactiveMP
enable_autocomplete_brackets(false);colorscheme!("GruvboxDark");
#include("function.jl")
include("GFECategorical.jl")
include("helpers.jl")

A,B,C,D = constructABCD(0.90,[2.,2.],2)

#@node PointMass Deterministic [out,in]
#@rule PointMass(:out, Marginalisation) (m_in::PointMass,) = begin
#    return m_in
#end
#
#@rule PointMass(:in, Marginalisation) (m_out::PointMass,) = begin
#    return missing
#end

@model function t_maze(A,B,C,T)

    z_0 = datavar(Vector{Float64})
    x = datavar(Vector{Float64},T)
    z = randomvar(T)
#    x = randomvar(T)

    z_prev = z_0

    for t in 1:T
        z[t] ~ Transition(z_prev,B[t])
        x[t] ~ GFECategorical(z[t], A) where {pipeline=ReactiveMP.RequireEverythingFunctionalDependencies(), meta=ForwardOnlyMeta,q=MeanField()}
#        x[t] ~ Dirichlet(C[t])
        z_prev = z[t]
    end
end;

T = 2

initmarginals = (
                 z = [Categorical(fill(1. /8. ,8)) for t in 1:T],
                 #x = [Dirichlet(C[t]) for t in 1:T],
                );

initmessages = (
                 z = [Categorical(fill(1. /8. ,8)) for t in 1:T],
                 #x = [Dirichlet(C[t]) for t in 1:T],
             );

its = 5
i = j = 1
Bs = (B[1],B[2])
result = inference(model = t_maze(A,Bs,C,T),
                   data= (z_0 = D, x=C),
                   initmarginals = initmarginals,
                   initmessages = initmessages,
                   free_energy=true,
                   iterations = its)
