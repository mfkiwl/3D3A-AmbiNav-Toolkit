function Tz = AmbiNav_ZTranslation(kd, maxOrder)
%AMBINAV_ZTRANSLATION Ambisonics translation along the z axis.
%   T = AMBINAV_ZTRANSLATION(KD, L) computes the ambisonic translation
%   coefficients matrix T, up to ambisonics order L and for non-dimensional
%   frequency KD, given by product of the angular wavenumber K and the
%   translation distance D.
%
%   KD may be a vector, in which case T is (L+1)^2-by-(L+1)^2-by-LENGTH(KD).
%
%   The ACN/N3D ambisonics normalization convention is assumed.
%
%   See also AMBINAV_TRANSLATION.

%   ==============================================================================
%   This file is part of the 3D3A AmbiNav Toolkit.
%   
%   Joseph G. Tylka <josephgt@princeton.edu>
%   3D Audio and Applied Acoustics (3D3A) Laboratory
%   Princeton University, Princeton, New Jersey 08544, USA
%   
%   MIT License
%   
%   Copyright (c) 2018 Princeton University
%   
%   Permission is hereby granted, free of charge, to any person obtaining a copy
%   of this software and associated documentation files (the "Software"), to deal
%   in the Software without restriction, including without limitation the rights
%   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%   copies of the Software, and to permit persons to whom the Software is
%   furnished to do so, subject to the following conditions:
%   
%   The above copyright notice and this permission notice shall be included in all
%   copies or substantial portions of the Software.
%   
%   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
%   SOFTWARE.
%   ==============================================================================

%   References:
%     [1] Gumerov and Duraiswami (2005) Fast Multipole Methods for the
%         Helmholtz Equation in Three Dimensions.
%     [2] Zotter (2009) Analysis and Synthesis of Sound-Radiation with
%         Spherical Arrays.

narginchk(2,2);

kdLen = length(kd);
HOATerms = (maxOrder + 1)^2;
Tz = zeros(HOATerms, (2*maxOrder+1)^2, kdLen);
zkd = (kd==0) | (kd < AmbiNav_KDThreshold());
nzkd = ~zkd;

zkdPos = find(zkd);
for ii = 1:sum(zkd)
    Tz(:,:,zkdPos(ii)) = eye(HOATerms, (2*maxOrder+1)^2);
end

% Step 1
for l = 0:2*maxOrder
    % Eq. 166 [2]; Eq. 3.2.103 [1]
    Tz(1,getACN(l,0)+1,nzkd) = ((-1)^l)*sqrt(2*l+1)*sphericalBesselJ(l,kd(nzkd));
end

% Step 2
for n = 1:maxOrder
    m = n;
    for l = n:(2*maxOrder-n)
        % Eq. 163 [2]; Eq. 3.2.104 [1]
        term1 = AmbiNav_CoefficientB(l,-m)*Tz(getACN(m-1,m-1)+1,getACN(l-1,m-1)+1,nzkd);
        term2 = AmbiNav_CoefficientB(l+1,m-1)*Tz(getACN(m-1,m-1)+1,getACN(l+1,m-1)+1,nzkd);
        Tz(getACN(n,m)+1,getACN(l,n)+1,nzkd) = (term1-term2)/AmbiNav_CoefficientB(m,-m);
    end
end

% Step 3
for m = 0:(maxOrder-1)
    for n = m:(maxOrder-1)
        for l = (n+1):(2*maxOrder - (n+1))
            % Eq. 163 [2]; Eq. 3.2.90 [1]
            term1 = AmbiNav_CoefficientA(l,m)*Tz(getACN(n,m)+1,getACN(l+1,m)+1,nzkd);
            term2 = AmbiNav_CoefficientA(l-1,m)*Tz(getACN(n,m)+1,getACN(l-1,m)+1,nzkd);
            term3 = AmbiNav_CoefficientA(n-1,m);
            if term3 ~= 0
                term3 = term3*Tz(getACN(n-1,m)+1,getACN(l,m)+1,nzkd);
            end
            Tz(getACN(n+1,m)+1,getACN(l,m)+1,nzkd) = -(term1-term2-term3)/AmbiNav_CoefficientA(n,m);
        end
    end
end

% Step 4
for n = 1:maxOrder
    for l = n:maxOrder
        for m = -1:-1:-n
            % Eq. 161 [2]; Eq. 3.2.92 [1]
            Tz(getACN(n,m)+1,getACN(l,m)+1,nzkd) = Tz(getACN(n,-m)+1,getACN(l,-m)+1,nzkd);
        end
    end
end

% Step 5
for n = 0:maxOrder
    for l = (n+1):maxOrder
        for m = -n:n
            % Eq. 162 [2]; Eq. 3.2.96 [1]
            coeff = (-1)^(n+l);
            Tz(getACN(l,m)+1,getACN(n,m)+1,nzkd) = coeff*Tz(getACN(n,m)+1,getACN(l,m)+1,nzkd);
        end
    end
end

% Make square matrix
Tz = Tz(:,1:HOATerms,:);

% Real-valued signal (N3D) correction
[nList, ~] = getAmbOrder(0:HOATerms-1);
for ii = 1:HOATerms
    for jj = 1:HOATerms
        if any(Tz(ii,jj,nzkd))
            coeff = (-1i)^(nList(jj)-nList(ii));
            Tz(ii,jj,nzkd) = coeff*Tz(ii,jj,nzkd);
        end
    end
end

end