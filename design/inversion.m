
function invA = inversion(A)
    n = size(A, 1);
    L = zeros(n);

    %Cholesky Decompostion
    for i = 1:n
        for j = 1:n
            temp = 0;
            for k = 1:n
                temp = temp + (L(i, k).*L(j, k));
            end
            if (i == j)
                L(i, j) = sqrt(A(i, j) - temp);
            else
                if (L(j, j) > 0)
                    L(i, j) = (A(i, j) - temp)./L(j, j);
                end
            end
            %disp(L(i, j));
        end
    end

    %Inversion of decomposed triangular matrix
    L1 = zeros(n);
    for k = 1:n
        L1(k, k) = 1/L(k, k);
        for i = k+1:n
            L1(i, k) = -L(i, k:i-1)*L1(k:i-1, k)/L(i, i);
        end
    end
%     for i=1:n
%         L1(i,i) = 1/L(i,i);
%         for j=1:i-1
%             s = 0;
%             for k=j:i-1
%                 s = s + L(i,k)*L1(k,j);
%             end
%             L1(i,j) = -s*L1(i,i);
%         end
%     end
    %obtaining the inverse
    invA = L1.'*L1;
end


