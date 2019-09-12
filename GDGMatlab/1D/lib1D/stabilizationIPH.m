function result=stabilizationIPH(coe_fun,vertices1,vertices2,vertex,basis_type_trial,basis_index_trial,der_trial,basis_type_test,basis_index_test,der_test)
% the function stabiliation() helps to compute the terms \mu\int_e [u][v]. See blue
% notebook for the calculations. At each interface I have 4 terms like
% u(x+)*v(x+) or u(x+)*v(x-) 
% It receveis verticesj to move from a refence to a local framework. The
% variable vertex contains the position of the interface.
h=vertices1(end)-vertices1(1);
if der_trial+der_test==0
result=FE_reference_basis_1D((vertex-vertices1(1))/h,basis_type_trial,basis_index_trial,der_trial)*FE_reference_basis_1D((vertex-vertices2(1))/h,basis_type_test,basis_index_test,der_test);
elseif der_trial+der_test==2
result=(1/h)^2*coe_fun(vertex)^2*FE_reference_basis_1D((vertex-vertices1(1))/h,basis_type_trial,basis_index_trial,der_trial)*FE_reference_basis_1D((vertex-vertices2(1))/h,basis_type_test,basis_index_test,der_test);
else
    printf('error in stabilizationIPH');
end

