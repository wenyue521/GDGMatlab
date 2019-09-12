function A=assemble_matrix_edges_IP(coe_fun,P,T,Tb_trial,Tb_test,Eb,matrixsize1,matrixsize2,basis_type_trial,basis_type_test,order_Gauss,alpha_coef)
% The function 'assemble_matrix_edges_IP' computes the edges terms of a IP
% formulation. Check Prof.Antonietti's slides for implementation.
%=== It receives 
% coe_fun= Diffusion coefficient.
% P, T=> vertex matrix of the mesh
% Tb_trial, Tb_test=> DOFs of the Finite_element space on the elements.
%Eb: edges matrix
% matrixsize1,matrixsiz2=> DOFS of the trial and test space.
% basis_type_trial/test=> FE space for trial and test
% order_Gauss=> order of Gauss quadrature.
%alpha_coef: coefficient DG penalization.

%=== Create sparse matrix and define parameters.
A=sparse(matrixsize1,matrixsize2);%create sparse matrix
number_of_elements=size(T,2); %number of Elements
number_of_local_basis_trial=size(Tb_trial,1); %number of trial local basis function on a single element
number_of_local_basis_test=size(Tb_test,1); %number of test local basis function on a single element
normal=zeros(2,1);
vintern=zeros(2,1);
tau=zeros(2,1);
%=== Loop to assembly the contribution over the boundary of triangles.
for n=1:number_of_elements % Loop over the triangles.
    for j=1:3 %loop over the edges
    current_edge=T(4+j,n);
    T_left=n;% It should be always equal to n
    if (Eb(3,current_edge)==n)
        T_right=Eb(4,current_edge);
    else
        T_right=Eb(3,current_edge);
    end
    vertex1=Eb(1,current_edge);%First vertex of the edge
    vertex2=Eb(2,current_edge);%Second vertex of the edge
    vertex_left_index=T((1:3),T_left);
    vertices_left=P(:,vertex_left_index); % vertices of the element on the left of the edge.
    edge_length=norm(P(:,vertex1)-P(:,vertex2),2);
    normal=find_normal(vertex1,vertex2,vertex_left_index,P);
    mu=alpha_coef/edge_length;
    [Gauss_nodes,Gauss_weights]=generate_Gauss_1D(P(:,vertex1),P(:,vertex2),order_Gauss);
    if(T_right~=-1) %Check if the edge is on the boundary
         vertices_right=P(:,T((1:3),T_right)); % vertices of the element on the left of the edge.
        for beta=1:number_of_local_basis_test %loop over trial functions on the element for test FE space.
           for alpha=1:number_of_local_basis_trial %loop over trial functions on the element for trial FE space.
                %===== Contribution of terms +\int \mu [[phi_j]][[\phi_i]]
                %contribution on same triangle \phi_j^+\phi_i^+
                int_value=mu*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,0);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_left)) +int_value; % Contribution from terms of the same triangle.
                % contribution on other triangle \phi_j^-\phi_i^+
                int_value=mu*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_right,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,0);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_right))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_right)) - int_value; % Contribution from term of the neighbouring.
                %====== Contribution of terms -\int \mu [[\phi_j]]{{\nabla phi_i}}
                %contribution on same triangle \phi_j^+\phi_i^+
                int_value=1/2*normal(1)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,1,0);
                int_value=int_value+ 1/2*normal(2)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,1);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))-int_value; % minus because we have - integral.
                % For symmetry I add the same in transpose position -\int \mu [[phi_i]][[\phi_j]]
                A(Tb_trial(alpha,T_left),Tb_test(beta,T_left))=A(Tb_trial(alpha,T_left),Tb_test(beta,T_left))-int_value;
                % contribution on other triangle \phi_j^-\phi_i^+
                int_value=1/2*normal(1)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_right,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,1,0);
                int_value=int_value+ 1/2*normal(2)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_right,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,1);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_right))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_right))+int_value;
                % For symmetry I add the same in transpose position -\int \mu [[phi_i]][[\phi_j]]
                A(Tb_trial(alpha,T_right),Tb_test(beta,T_left))=A(Tb_trial(alpha,T_right),Tb_test(beta,T_left))+int_value;
           end
        end
    elseif(T_right==-1)
        for beta=1:number_of_local_basis_test %loop over trial functions on the element for test FE space.
           for alpha=1:number_of_local_basis_trial %loop over trial functions on the element for trial FE space.
                % Contribution of terms +\int \mu [[phi_j]][[\phi_i]]
                int_value=mu*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,0);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_left)) +int_value; % Contribution from terms of the same triangle.
                %====== Contribution of terms -\int \mu [[\phi_j]]{{\nabla phi_i}}
                int_value=normal(1)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,1,0);
                int_value=int_value+normal(2)*Gauss_quadrature_1D_trial_test(coe_fun,Gauss_nodes,Gauss_weights,vertices_left,vertices_left,basis_type_trial,alpha,0,0,basis_type_test,beta,0,1);
                A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))=A(Tb_test(beta,T_left),Tb_trial(alpha,T_left))-int_value;
                A(Tb_trial(alpha,T_left),Tb_test(beta,T_left))=A(Tb_trial(alpha,T_left),Tb_test(beta,T_left))-int_value;
           end
        end
    end
    end
end
end
