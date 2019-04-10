
%Find the orientation error with regard to the inconuity at +pi/-pi
%

function orientError = min_orient_error(error)

    errorMat = [error, error+2*pi, error-2*pi];
    errorAbsMat = [abs(error) abs(error+2*pi), abs(error-2*pi)];
    [~,index] = min(errorAbsMat,[],2);
    
    orientError = zeros(length(error),1);
    for i = 1:length(error)
       orientError(i) = errorMat(i,index(i));
    end
end
