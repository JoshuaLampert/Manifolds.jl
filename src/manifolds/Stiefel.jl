@doc raw"""
    Stiefel{T,𝔽} <: AbstractDecoratorManifold{𝔽}

The Stiefel manifold consists of all ``n×k``, ``n ≥ k`` unitary matrices, i.e.

````math
\operatorname{St}(n,k) = \bigl\{ p ∈ 𝔽^{n×k}\ \big|\ p^{\mathrm{H}}p = I_k \bigr\},
````

where ``𝔽 ∈ \{ℝ, ℂ\}``,
``⋅^{\mathrm{H}}`` denotes the complex conjugate transpose or Hermitian, and
``I_k ∈ ℝ^{k×k}`` denotes the ``k×k`` identity matrix.

The tangent space at a point ``p ∈ \mathcal M`` is given by

````math
T_p \mathcal M = \{ X ∈ 𝔽^{n×k} : p^{\mathrm{H}}X + X^{\mathrm{H}}p = 0_k\},
````

where ``0_k`` is the ``k×k`` zero matrix.

This manifold is modeled as an embedded manifold to the [`Euclidean`](@ref), i.e.
several functions like the [`inner`](@ref inner(::Euclidean, ::Any...)) product and the
[`zero_vector`](@ref zero_vector(::Euclidean, ::Any...)) are inherited from the embedding.

The manifold is named after
[Eduard L. Stiefel](https://en.wikipedia.org/wiki/Eduard_Stiefel) (1909–1978).

# Constructor
    Stiefel(n, k, field=ℝ; parameter::Symbol=:type)

Generate the (real-valued) Stiefel manifold of ``n×k`` dimensional orthonormal matrices.
"""
struct Stiefel{T,𝔽} <: AbstractDecoratorManifold{𝔽}
    size::T
end

function Stiefel(n::Int, k::Int, field::AbstractNumbers=ℝ; parameter::Symbol=:type)
    size = wrap_type_parameter(parameter, (n, k))
    return Stiefel{typeof(size),field}(size)
end

function active_traits(f, ::Stiefel, args...)
    return merge_traits(IsIsometricEmbeddedManifold(), IsDefaultMetric(EuclideanMetric()))
end

function allocation_promotion_function(::Stiefel{<:Any,ℂ}, ::Any, ::Tuple)
    return complex
end

@doc raw"""
    change_representer(M::Stiefel, ::EuclideanMetric, p, X)

Change `X` to the corresponding representer of a cotangent vector at `p`.
Since the [`Stiefel`](@ref) manifold `M`, is isometrically embedded, this is the identity
"""
change_representer(::Stiefel, ::EuclideanMetric, ::Any, ::Any)

function change_representer!(M::Stiefel, Y, ::EuclideanMetric, p, X)
    copyto!(M, Y, p, X)
    return Y
end

@doc raw"""
    change_metric(M::Stiefel, ::EuclideanMetric, p X)

Change `X` to the corresponding vector with respect to the metric of the [`Stiefel`](@ref) `M`,
which is just the identity, since the manifold is isometrically embedded.
"""
change_metric(M::Stiefel, ::EuclideanMetric, ::Any, ::Any)

function change_metric!(::Stiefel, Y, ::EuclideanMetric, p, X)
    copyto!(Y, X)
    return Y
end

@doc raw"""
    check_point(M::Stiefel, p; kwargs...)

Check whether `p` is a valid point on the [`Stiefel`](@ref) `M`=``\operatorname{St}(n,k)``, i.e. that it has the right
[`AbstractNumbers`](@extref ManifoldsBase number-system) type and ``p^{\mathrm{H}}p`` is (approximately) the identity, where ``⋅^{\mathrm{H}}`` is the
complex conjugate transpose. The settings for approximately can be set with `kwargs...`.
"""
function check_point(M::Stiefel, p; kwargs...)
    cks = check_size(M, p)
    (cks === nothing) || return cks
    c = p' * p
    if !isapprox(c, one(c); kwargs...)
        return DomainError(
            norm(c - one(c)),
            "The point $(p) does not lie on $(M), because p'p is not the unit matrix.",
        )
    end
    return nothing
end

@doc raw"""
    check_vector(M::Stiefel, p, X; kwargs...)

Checks whether `X` is a valid tangent vector at `p` on the [`Stiefel`](@ref)
`M`=``\operatorname{St}(n,k)``, i.e. the [`AbstractNumbers`](@extref ManifoldsBase number-system) fits and
it (approximately) holds that ``p^{\mathrm{H}}X + X^{\mathrm{H}}p = 0``.
The settings for approximately can be set with `kwargs...`.
"""
function check_vector(M::Stiefel, p, X; kwargs...)
    n, k = get_parameter(M.size)
    cks = check_size(M, p, X)
    cks === nothing || return cks
    if !isapprox(p' * X, -conj(X' * p); kwargs...)
        return DomainError(
            norm(p' * X + conj(X' * p)),
            "The matrix $(X) is does not lie in the tangent space of $(p) on the Stiefel manifold of dimension ($(n),$(k)), since p'X + X'p is not the zero matrix.",
        )
    end
    return nothing
end

"""
    default_inverse_retraction_method(M::Stiefel)

Return [`PolarInverseRetraction`](@extref `ManifoldsBase.PolarInverseRetraction`) as the default inverse retraction for the
[`Stiefel`](@ref) manifold.
"""
default_inverse_retraction_method(::Stiefel) = PolarInverseRetraction()

"""
    default_retraction_method(M::Stiefel)

Return [`PolarRetraction`](@extref `ManifoldsBase.PolarRetraction`) as the default retraction for the [`Stiefel`](@ref) manifold.
"""
default_retraction_method(::Stiefel) = PolarRetraction()

"""
    default_vector_transport_method(M::Stiefel)

Return the [`DifferentiatedRetractionVectorTransport`](@extref `ManifoldsBase.DifferentiatedRetractionVectorTransport`) of the [`PolarRetraction`]([`PolarRetraction`](@extref `ManifoldsBase.PolarRetraction`)
as the default vector transport method for the [`Stiefel`](@ref) manifold.
"""
function default_vector_transport_method(::Stiefel)
    return DifferentiatedRetractionVectorTransport(PolarRetraction())
end

embed(::Stiefel, p) = p
embed(::Stiefel, p, X) = X

function get_embedding(::Stiefel{TypeParameter{Tuple{n,k}},𝔽}) where {n,k,𝔽}
    return Euclidean(n, k; field=𝔽)
end
function get_embedding(M::Stiefel{Tuple{Int,Int},𝔽}) where {𝔽}
    n, k = get_parameter(M.size)
    return Euclidean(n, k; field=𝔽, parameter=:field)
end

@doc raw"""
    inverse_retract(M::Stiefel, p, q, ::PolarInverseRetraction)

Compute the inverse retraction based on a singular value decomposition
for two points `p`, `q` on the [`Stiefel`](@ref) manifold `M`.
This follows the following approach: From the Polar retraction we know that

````math
\operatorname{retr}_p^{-1}q = qs - t
````

if such a symmetric positive definite ``k×k`` matrix exists. Since ``qs - t``
is also a tangent vector at ``p`` we obtain

````math
p^{\mathrm{H}}qs + s(p^{\mathrm{H}}q)^{\mathrm{H}} + 2I_k = 0,
````
which can either be solved by a Lyapunov approach or a continuous-time
algebraic Riccati equation.

This implementation follows the Lyapunov approach.
"""
inverse_retract(::Stiefel, ::Any, ::Any, ::PolarInverseRetraction)

@doc raw"""
    inverse_retract(M::Stiefel, p, q, ::QRInverseRetraction)

Compute the inverse retraction based on a qr decomposition
for two points `p`, `q` on the [`Stiefel`](@ref) manifold `M` and return
the resulting tangent vector in `X`. The computation follows Algorithm 1
in [KanekoFioriTanaka:2013](@cite).
"""
inverse_retract(::Stiefel, ::Any, ::Any, ::QRInverseRetraction)

function _stiefel_inv_retr_qr_mul_by_r_generic!(M::Stiefel, X, q, R, A)
    n, k = get_parameter(M.size)
    @inbounds for i in 1:k
        b = zeros(eltype(R), i)
        b[i] = 1
        b[1:(end - 1)] = -transpose(R[1:(i - 1), 1:(i - 1)]) * A[i, 1:(i - 1)]
        R[1:i, i] = A[1:i, 1:i] \ b
    end
    #TODO: replace with this once it's supported by StaticArrays
    #return mul!(X, q, UpperTriangular(R))
    return mul!(X, q, R)
end

function _stiefel_inv_retr_qr_mul_by_r!(
    ::Stiefel{TypeParameter{Tuple{n,1}}},
    X,
    q,
    A,
    ::Type,
) where {n}
    @inbounds R = SMatrix{1,1}(inv(A[1, 1]))
    return mul!(X, q, R)
end
function _stiefel_inv_retr_qr_mul_by_r!(
    M::Stiefel{TypeParameter{Tuple{n,1}}},
    X,
    q,
    A::StaticArray,
    ::Type{ElT},
) where {n,ElT}
    return invoke(
        _stiefel_inv_retr_qr_mul_by_r!,
        Tuple{
            Stiefel{TypeParameter{Tuple{n,1}}},
            typeof(X),
            typeof(q),
            AbstractArray,
            typeof(ElT),
        },
        M,
        X,
        q,
        A,
        ElT,
    )
end
function _stiefel_inv_retr_qr_mul_by_r!(
    ::Stiefel{TypeParameter{Tuple{n,2}}},
    X,
    q,
    A,
    ::Type{ElT},
) where {n,ElT}
    R11 = inv(A[1, 1])
    @inbounds R =
        hcat(SA[R11, zero(ElT)], A[SOneTo(2), SOneTo(2)] \ SA[-R11 * A[2, 1], one(ElT)])

    #TODO: replace with this once it's supported by StaticArrays
    #return mul!(X, q, UpperTriangular(R))
    return mul!(X, q, R)
end
function _stiefel_inv_retr_qr_mul_by_r!(
    M::Stiefel{TypeParameter{Tuple{n,2}}},
    X,
    q,
    A::StaticArray,
    ::Type{ElT},
) where {n,ElT}
    return invoke(
        _stiefel_inv_retr_qr_mul_by_r!,
        Tuple{
            Stiefel{TypeParameter{Tuple{n,2}}},
            typeof(X),
            typeof(q),
            AbstractArray,
            typeof(ElT),
        },
        M,
        X,
        q,
        A,
        ElT,
    )
end
function _stiefel_inv_retr_qr_mul_by_r!(
    M::Stiefel{TypeParameter{Tuple{n,k}}},
    X,
    q,
    A::StaticArray,
    ::Type{ElT},
) where {n,k,ElT}
    R = zeros(MMatrix{k,k,ElT})
    return _stiefel_inv_retr_qr_mul_by_r_generic!(M, X, q, R, A)
end
function _stiefel_inv_retr_qr_mul_by_r!(M::Stiefel, X, q, A, ::Type{ElT}) where {ElT}
    n, k = get_parameter(M.size)
    R = zeros(ElT, k, k)
    return _stiefel_inv_retr_qr_mul_by_r_generic!(M, X, q, R, A)
end

function inverse_retract_polar!(::Stiefel, X, p, q)
    A = p' * q
    H = -2 * one(p' * p)
    B = lyap(A, H)
    mul!(X, q, B)
    X .-= p
    return X
end
function inverse_retract_qr!(M::Stiefel, X, p, q)
    n, k = get_parameter(M.size)
    A = p' * q
    @boundscheck size(A) === (k, k)
    ElT = typeof(one(eltype(p)) * one(eltype(q)))
    _stiefel_inv_retr_qr_mul_by_r!(M, X, q, A, ElT)
    X .-= p
    return X
end

function _isapprox(M::Stiefel, p, X, Y; atol=sqrt(max_eps(X, Y)), kwargs...)
    return isapprox(norm(M, p, X - Y), 0; atol=atol, kwargs...)
end

"""
    is_flat(M::Stiefel)

Return true if [`Stiefel`](@ref) `M` is one-dimensional.
"""
is_flat(M::Stiefel) = manifold_dimension(M) == 1

@doc raw"""
    manifold_dimension(M::Stiefel)

Return the dimension of the [`Stiefel`](@ref) manifold `M`=``\operatorname{St}(n,k,𝔽)``.
The dimension is given by

````math
\begin{aligned}
\dim \mathrm{St}(n, k, ℝ) &= nk - \frac{1}{2}k(k+1)\\
\dim \mathrm{St}(n, k, ℂ) &= 2nk - k^2\\
\dim \mathrm{St}(n, k, ℍ) &= 4nk - k(2k-1)
\end{aligned}
````
"""
function manifold_dimension(M::Stiefel{<:Any,ℝ})
    n, k = get_parameter(M.size)
    return n * k - div(k * (k + 1), 2)
end
function manifold_dimension(M::Stiefel{<:Any,ℂ})
    n, k = get_parameter(M.size)
    return 2 * n * k - k * k
end
function manifold_dimension(M::Stiefel{<:Any,ℍ})
    n, k = get_parameter(M.size)
    return 4 * n * k - k * (2k - 1)
end

@doc raw"""
    rand(::Stiefel; vector_at=nothing, σ::Real=1.0)

When `vector_at` is `nothing`, return a random (Gaussian) point `x` on the [`Stiefel`](@ref)
manifold `M` by generating a (Gaussian) matrix with standard deviation `σ` and return the
orthogonalized version, i.e. return the Q component of the QR decomposition of the random
matrix of size ``n×k``.

When `vector_at` is not `nothing`, return a (Gaussian) random vector from the tangent space
``T_{vector\_at}\mathrm{St}(n,k)`` with mean zero and standard deviation `σ` by projecting a
random Matrix onto the tangent vector at `vector_at`.
"""
rand(::Stiefel; σ::Real=1.0)

function Random.rand!(
    rng::AbstractRNG,
    M::Stiefel{<:Any,𝔽},
    pX;
    vector_at=nothing,
    σ::Real=one(real(eltype(pX))),
) where {𝔽}
    n, k = get_parameter(M.size)
    if vector_at === nothing
        A = σ * randn(rng, 𝔽 === ℝ ? Float64 : ComplexF64, n, k)
        pX .= Matrix(qr(A).Q)
    else
        Z = σ * randn(rng, eltype(pX), size(pX))
        project!(M, pX, vector_at, Z)
        normalize!(pX)
    end
    return pX
end

@doc raw"""
    retract(::Stiefel, p, X, ::CayleyRetraction)

Compute the retraction on the [`Stiefel`](@ref) that is based on the Cayley transform[Zhu:2016](@cite).
Using
````math
  W_{p,X} = \operatorname{P}_pXp^{\mathrm{H}} - pX^{\mathrm{H}}\operatorname{P_p}
  \quad\text{where}
  \operatorname{P}_p = I - \frac{1}{2}pp^{\mathrm{H}}
````
the formula reads
````math
    \operatorname{retr}_pX = \Bigl(I - \frac{1}{2}W_{p,X}\Bigr)^{-1}\Bigl(I + \frac{1}{2}W_{p,X}\Bigr)p.
````

It is implemented as the case ``m=1`` of the `PadeRetraction`.
"""
retract(::Stiefel, ::Any, ::Any, ::CayleyRetraction)

@doc raw"""
    retract(M::Stiefel, p, X, ::PadeRetraction{m})

Compute the retraction on the [`Stiefel`](@ref) manifold `M` based on the Padé approximation of order ``m`` [ZhuDuan:2018](@cite).
Let ``p_m`` and ``q_m`` be defined for any matrix ``A ∈ ℝ^{n×x}`` as

````math
  p_m(A) = \sum_{k=0}^m \frac{(2m-k)!m!}{(2m)!(m-k)!}\frac{A^k}{k!}
````

and

````math
  q_m(A) = \sum_{k=0}^m \frac{(2m-k)!m!}{(2m)!(m-k)!}\frac{(-A)^k}{k!}
````

respectively. Then the Padé approximation (of the matrix exponential ``\exp(A)``) reads

````math
  r_m(A) = q_m(A)^{-1}p_m(A)
````

Defining further

````math
  W_{p,X} = \operatorname{P}_pXp^{\mathrm{H}} - pX^{\mathrm{H}}\operatorname{P_p}
  \quad\text{where }
  \operatorname{P}_p = I - \frac{1}{2}pp^{\mathrm{H}}
````

the retraction reads

````math
  \operatorname{retr}_pX = r_m(W_{p,X})p
````
"""
retract(::Stiefel, ::Any, ::Any, ::PadeRetraction)

@doc raw"""
    retract(M::Stiefel, p, X, ::PolarRetraction)

Compute the SVD-based retraction [`PolarRetraction`](@extref `ManifoldsBase.PolarRetraction`) on the
[`Stiefel`](@ref) manifold `M`. With ``USV = p + X`` the retraction reads

````math
\operatorname{retr}_p X = U\bar{V}^\mathrm{H}.
````
"""
retract(::Stiefel, ::Any, ::Any, ::PolarRetraction)

@doc raw"""
    retract(M::Stiefel, p, X, ::QRRetraction)

Compute the QR-based retraction [`QRRetraction`](@extref `ManifoldsBase.QRRetraction`) on the
[`Stiefel`](@ref) manifold `M`. With ``QR = p + X`` the retraction reads

````math
\operatorname{retr}_p X = QD,
````

where ``D`` is a ``n×k`` matrix with

````math
D = \operatorname{diag}\bigl(\operatorname{sgn}(R_{ii}+0,5)_{i=1}^k \bigr),
````

where ``\operatorname{sgn}(p) = \begin{cases}
1 & \text{ for } p > 0,\\
0 & \text{ for } p = 0,\\
-1& \text{ for } p < 0.
\end{cases}``
"""
retract(::Stiefel, ::Any, ::Any, ::QRRetraction)

_qrfac_to_q(qrfac) = Matrix(qrfac.Q)
_qrfac_to_q(qrfac::StaticArrays.QR) = qrfac.Q

function ManifoldsBase.retract_pade!(M::Stiefel, q, p, X, m::PadeRetraction)
    return ManifoldsBase.retract_pade_fused!(M, q, p, X, one(eltype(p)), m)
end

function ManifoldsBase.retract_pade_fused!(
    ::Stiefel,
    q,
    p,
    X,
    t::Number,
    ::PadeRetraction{m},
) where {m}
    tX = t * X
    Pp = I - 1 // 2 * p * p'
    WpX = Pp * tX * p' - p * tX' * Pp
    pm = zeros(eltype(WpX), size(WpX))
    qm = zeros(eltype(WpX), size(WpX))
    WpXk = similar(WpX)
    copyto!(WpXk, factorial(m) / factorial(2 * m) * I) # factorial factor independent of k
    for k in 0:m
        # incrementally build (2m-k)!/(m-k)!(k)! for k > 0, i.e.
        # remove factor (2m-k+1) in the nominator, (m-k+1) in the denominator and multiply by 1/k
        WpXk .*= (k == 0 ? 2 : (m - k + 1) / ((2 * m - k + 1) * k))
        pm .+= WpXk
        if k % 2 == 0
            qm .+= WpXk
        else
            qm .-= WpXk
        end
        WpXk *= WpX
    end
    return copyto!(q, (qm \ pm) * p)
end

function ManifoldsBase.retract_polar!(M::Stiefel, q, p, X)
    return ManifoldsBase.retract_polar_fused!(M, q, p, X, one(eltype(p)))
end
function ManifoldsBase.retract_polar_fused!(::Stiefel, q, p, X, t::Number)
    q .= p .+ t .* X
    s = svd(q)
    return mul!(q, s.U, s.Vt)
end

function ManifoldsBase.retract_qr!(M::Stiefel, q, p, X)
    return ManifoldsBase.retract_qr_fused!(M, q, p, X, one(eltype(p)))
end
function ManifoldsBase.retract_qr_fused!(::Stiefel, q, p, X, t::Number)
    q .= p .+ t .* X
    qrfac = qr(q)
    d = diag(qrfac.R)
    D = Diagonal(sign.(sign.(d .+ 1 // 2)))
    return mul!(q, _qrfac_to_q(qrfac), D)
end

@doc raw"""
    representation_size(M::Stiefel)

Returns the representation size of the [`Stiefel`](@ref) `M`=``\operatorname{St}(n,k)``,
i.e. `(n,k)`, which is the matrix dimensions.
"""
representation_size(M::Stiefel) = get_parameter(M.size)

function Base.show(io::IO, ::Stiefel{TypeParameter{Tuple{n,k}},𝔽}) where {n,k,𝔽}
    return print(io, "Stiefel($(n), $(k), $(𝔽))")
end
function Base.show(io::IO, M::Stiefel{Tuple{Int,Int},𝔽}) where {𝔽}
    n, k = get_parameter(M.size)
    return print(io, "Stiefel($(n), $(k), $(𝔽); parameter=:field)")
end

@doc raw"""
    vector_transport_direction(::Stiefel, p, X, d, ::DifferentiatedRetractionVectorTransport{CayleyRetraction})

Compute the vector transport given by the differentiated retraction of the [`CayleyRetraction`](@extref `ManifoldsBase.CayleyRetraction`), cf. [Zhu:2016](@cite) Equation (17).

The formula reads
````math
\operatorname{T}_{p,d}(X) =
\Bigl(I - \frac{1}{2}W_{p,d}\Bigr)^{-1}W_{p,X}\Bigl(I - \frac{1}{2}W_{p,d}\Bigr)^{-1}p,
````
with
````math
  W_{p,X} = \operatorname{P}_pXp^{\mathrm{H}} - pX^{\mathrm{H}}\operatorname{P_p}
  \quad\text{where }
  \operatorname{P}_p = I - \frac{1}{2}pp^{\mathrm{H}}
````

Since this is the differentiated retraction as a vector transport, the result will be in the
tangent space at ``q=\operatorname{retr}_p(d)`` using the [`CayleyRetraction`](@extref `ManifoldsBase.CayleyRetraction`).
"""
vector_transport_direction(
    M::Stiefel,
    p,
    X,
    d,
    ::DifferentiatedRetractionVectorTransport{CayleyRetraction},
)

@doc raw"""
    vector_transport_direction(M::Stiefel, p, X, d, DifferentiatedRetractionVectorTransport{PolarRetraction})

Compute the vector transport by computing the push forward of
[`retract(::Stiefel, ::Any, ::Any, ::PolarRetraction)`](@ref) Section 3.5 of [Zhu:2016](@cite):

```math
T_{p,d}^{\text{Pol}}(X) = q*Λ + (I-qq^{\mathrm{T}})X(1+d^\mathrm{T}d)^{-\frac{1}{2}},
```

where ``q = \operatorname{retr}^{\mathrm{Pol}}_p(d)``, and ``Λ`` is the unique solution of the Sylvester equation

```math
    Λ(I+d^\mathrm{T}d)^{\frac{1}{2}} + (I + d^\mathrm{T}d)^{\frac{1}{2}} = q^\mathrm{T}X - X^\mathrm{T}q
```
"""
vector_transport_direction(
    ::Stiefel,
    ::Any,
    ::Any,
    ::Any,
    ::DifferentiatedRetractionVectorTransport{PolarRetraction},
)

@doc raw"""
    vector_transport_direction(M::Stiefel, p, X, d, DifferentiatedRetractionVectorTransport{QRRetraction})

Compute the vector transport by computing the push forward of the
[`retract(::Stiefel, ::Any, ::Any, ::QRRetraction)`](@ref),
See  [AbsilMahonySepulchre:2008](@cite), p. 173, or Section 3.5 of [Zhu:2016](@cite).
```math
T_{p,d}^{\text{QR}}(X) = q*\rho_{\mathrm{s}}(q^\mathrm{T}XR^{-1}) + (I-qq^{\mathrm{T}})XR^{-1},
```
where ``q = \operatorname{retr}^{\mathrm{QR}}_p(d)``, ``R`` is the ``R`` factor of the QR
decomposition of ``p + d``, and
```math
\bigl( \rho_{\mathrm{s}}(A) \bigr)_{ij}
= \begin{cases}
A_{ij}&\text{ if } i > j\\
0 \text{ if } i = j\\
-A_{ji} \text{ if } i < j.\\
\end{cases}
```
"""
vector_transport_direction(
    ::Stiefel,
    ::Any,
    ::Any,
    ::Any,
    ::DifferentiatedRetractionVectorTransport{QRRetraction},
)

function vector_transport_direction_diff!(::Stiefel, Y, p, X, d, ::CayleyRetraction)
    Pp = I - 1 // 2 * p * p'
    Wpd = Pp * d * p' - p * d' * Pp
    WpX = Pp * X * p' - p * X' * Pp
    q1 = I - 1 // 2 * Wpd
    return copyto!(Y, (q1 \ WpX) * (q1 \ p))
end

function vector_transport_direction_diff!(M::Stiefel, Y, p, X, d, ::PolarRetraction)
    q = retract(M, p, d, PolarRetraction())
    Iddsqrt = sqrt(I + d' * d)
    Λ = sylvester(Iddsqrt, Iddsqrt, -q' * X + X' * q)
    return copyto!(Y, q * Λ + (X - q * (q' * X)) / Iddsqrt)
end
function vector_transport_direction_diff!(M::Stiefel, Y, p, X, d, ::QRRetraction)
    q = retract(M, p, d, QRRetraction())

    # use the QR factorization with positive diagonal of R
    pdR = qr(p + d).R
    s = sign.(diag(pdR))
    s[s .== 0] .= 1
    rf = UpperTriangular(Diagonal(s)' * pdR)

    Xrf = X / rf
    qtXrf = q' * Xrf
    return copyto!(
        Y,
        q * (UpperTriangular(qtXrf) - UpperTriangular(qtXrf)') + Xrf - q * qtXrf,
    )
end

@doc raw"""
    vector_transport_to(M::Stiefel, p, X, q, DifferentiatedRetractionVectorTransport{PolarRetraction})

Compute the vector transport by computing the push forward of the
[`retract(M::Stiefel, ::Any, ::Any, ::PolarRetraction)`](@ref), see
Section 4 of [HuangGallivanAbsil:2015](@cite) or  Section 3.5 of [Zhu:2016](@cite):

```math
T_{q\gets p}^{\text{Pol}}(X) = q*Λ + (I-qq^{\mathrm{T}})X(1+d^\mathrm{T}d)^{-\frac{1}{2}},
```

where ``d = \bigl( \operatorname{retr}^{\mathrm{Pol}}_p\bigr)^{-1}(q)``,
and ``Λ`` is the unique solution of the Sylvester equation

```math
    Λ(I+d^\mathrm{T}d)^{\frac{1}{2}} + (I + d^\mathrm{T}d)^{\frac{1}{2}} = q^\mathrm{T}X - X^\mathrm{T}q
```
"""
vector_transport_to(
    ::Stiefel,
    ::Any,
    ::Any,
    ::Any,
    ::DifferentiatedRetractionVectorTransport{PolarRetraction},
)

@doc raw"""
    vector_transport_to(M::Stiefel, p, X, q, DifferentiatedRetractionVectorTransport{QRRetraction})

Compute the vector transport by computing the push forward of the
[`retract(M::Stiefel, ::Any, ::Any, ::QRRetraction)`](@ref),
see  [AbsilMahonySepulchre:2008](@cite), p. 173, or Section 3.5 of [Zhu:2016](@cite).

```math
T_{q \gets p}^{\text{QR}}(X) = q*\rho_{\mathrm{s}}(q^\mathrm{T}XR^{-1}) + (I-qq^{\mathrm{T}})XR^{-1},
```
where ``d = \bigl(\operatorname{retr}^{\mathrm{QR}}\bigr)^{-1}_p(q)``, ``R`` is the ``R`` factor of the QR
decomposition of ``p+X``, and
```math
\bigl( \rho_{\mathrm{s}}(A) \bigr)_{ij}
= \begin{cases}
A_{ij}&\text{ if } i > j\\
0 \text{ if } i = j\\
-A_{ji} \text{ if } i < j.\\
\end{cases}
```
"""
vector_transport_to(
    ::Stiefel,
    ::Any,
    ::Any,
    ::Any,
    ::DifferentiatedRetractionVectorTransport{QRRetraction},
)

@doc raw"""
    vector_transport_to(M::Stiefel, p, X, q, ::ProjectionTransport)

Compute a vector transport by projection, i.e. project `X` from the tangent space at `p` by
projection it onto the tangent space at `q`.
"""
vector_transport_to(::Stiefel, ::Any, ::Any, ::Any, ::ProjectionTransport)

function vector_transport_to_diff!(M::Stiefel, Y, p, X, q, ::PolarRetraction)
    d = inverse_retract(M, p, q, PolarInverseRetraction())
    Iddsqrt = sqrt(I + d' * d)
    Λ = sylvester(Iddsqrt, Iddsqrt, -q' * X + X' * q)
    return copyto!(Y, q * Λ + (X - q * (q' * X)) / Iddsqrt)
end
function vector_transport_to_diff!(M::Stiefel, Y, p, X, q, ::QRRetraction)
    d = inverse_retract(M, p, q, QRInverseRetraction())

    # use the QR factorization with positive diagonal of R
    pdR = qr(p + d).R
    s = sign.(diag(pdR))
    s[s .== 0] .= 1
    rf = UpperTriangular(Diagonal(s)' * pdR)
    Xrf = X / rf
    qtXrf = q' * Xrf
    return copyto!(
        Y,
        q * (UpperTriangular(qtXrf) - UpperTriangular(qtXrf)') + Xrf - q * qtXrf,
    )
end
