#Functions that outline the model
"""
# Boltzman Helper Function

    boltzman(p::TPC,T::Float64)

Takes a `TPC` object and the temperature (`T`) returning the metabolic rate.
"""
function boltzman(p::TPC,T::Float64)
    p.B0 * exp( (-p.E/k) * ((1/T)-(1/p.Tr)) )
end

"""
# Michaelis-Menten Kinetics

    limit(N::Float64,kN::Float64)

Gives a limiting term acording to Michaelis-Menten kinetics that ranges from 0-1
"""
function limit(N::Float64,kN::Float64)
    N/(N+kN)
end

"""
# Individual Flux

## Autotroph

    individual_flux(sp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},i::Int64,s_i::Int64,c_i::Int64)

Returns the individual flux for an autotroph species
"""
function individual_flux(comp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},
    i::Int64)

    in = C[i] * comp.ϵ * limit(C[p[:s_i]],comp.ks) * boltzman(comp.P,p[:T])
    out = (C[i] * boltzman(comp.R,p[:T])) + (C[i] * comp.D) + (C[i] * C[i] * comp.a)
    return(in - out)
end

"""
## Heterotroph

    individual_flux(sp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},i::Int64,s_i::Int64,c_i::Int64)

or for a heterotroph species
"""
function individual_flux(comp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},
    i::Int64)

    in = C[i] * comp.ϵ * limit(C[p[:s_i]],comp.ks) * boltzman(comp.μ,p[:T]) * limit(C[p[:c_i]],comp.kc)
    out = (C[i] * boltzman(comp.R,p[:T])) + (C[i] * comp.D) + (C[i] * C[i] * comp.a)
    return(in - out)
end

"""
# Carbon Loss Flux
## Autotroph

C_out(sp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},j::Int64,s_i::Int64,c_i::Int64)

Returns the amount of carbon entering the carbon pool from a given autotroph
species.
"""
function C_out(sp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},
    j::Int64)

    out = (C[j] * (1-sp.ϵ) * limit(C[p[:s_i]],sp.ks) * boltzman(sp.P,p[:T])) +
          (C[j] * sp.D)
end

"""
## Heterotroph

C_out(sp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},j::Int64,s_i::Int64,c_i::Int64)

Returns the amount of carbon entering the carbon pool from a given heterotroph
species.
"""
function C_out(sp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},
    j::Int64)

    out = (C[j] * (1-sp.ϵ) * limit(C[p[:s_i]],sp.ks) * boltzman(sp.μ,p[:T]) * limit(C[p[:c_i]],sp.kc)) +
          (C[j] * sp.D)
end



"""
# Carbon Pool Flux

    individual_flux(comp::Cpool,p::Dict{Symbol,Any},C::Array{Float64},i::Int64,s_i::Int64,c_i::Int64)

Gives the total carbon pool flux including flows from autotrophs and
heterotrophs
"""
function individual_flux(comp::Cpool,p::Dict{Symbol,Any},C::Array{Float64},
    i::Int64)

    in = 0.0
    out = 0.0

    if comp.linked
        for j in 1:p[:Eco].N_sp
            if (j != p[:s_i]) && (j != p[:c_i])
                in += C_out(p[:Eco].sp[j],p,C,j)
                #heterotroph uptake
                if isa(p[:Eco].sp[j],Heterotroph)
                    sp = p[:Eco].sp[j]
                    out += C[j] * limit(C[p[:s_i]],sp.ks) *
                           boltzman(sp.μ,p[:T]) * limit(C[p[:c_i]],sp.kc)
                end
            end
        end
    end
    return(in - out)
end

"""
# Nutrient Gain Flux
## Autotroph

S_out(sp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},j::Int64,s_i::Int64,c_i::Int64)

Returns the amount of nutrients leaving the nutrient pool from a given autotroph
species.
"""
function S_out(sp::Autotroph,p::Dict{Symbol,Any},C::Array{Float64},
    j::Int64)

    out = C[j] * limit(C[p[:s_i]],sp.ks) * boltzman(sp.P,p[:T])
end

"""
## Heterotroph

S_out(sp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},j::Int64,s_i::Int64,c_i::Int64)

Returns the amount of nutrients leaving the nutrient pool from a given heterotroph
species.
"""
function S_out(sp::Heterotroph,p::Dict{Symbol,Any},C::Array{Float64},
    j::Int64)

    out = C[j] * limit(C[p[:s_i]],sp.ks) * boltzman(sp.μ,p[:T]) * limit(C[p[:c_i]],sp.kc)
end


"""
# Nutrient Pool Flux

    individual_flux(comp::Spool,p::Dict{Symbol,Any},C::Array{Float64},i::Int64,s_i::Int64,c_i::Int64)

Gives the total nutrient pool flux. Is determined by the uptake by living
compartments and a constant gain term
"""
function individual_flux(comp::Spool,p::Dict{Symbol,Any},C::Array{Float64},
    i::Int64)

    in = comp.R
    out = 0.0

    for j in 1:p[:Eco].N_sp
        if (j != s_i) && (j != c_i)
            out += S_out(p[:Eco].sp[j],p,C,j)
        end
    end


    return(in - out)
end



"""
# Differential Function

    dcdt(dc,c,p,t)

Defines the system of equations to be used by the solver.
"""
function dcdt(du,u,p,t)

#move through and return dc
    for i in 1:length(p[:Eco].sp)
        du[i] = individual_flux(p[:Eco].sp[i],p,u,i)
    end

    return(du)
end
