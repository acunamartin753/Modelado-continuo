# Para comprimir una imagen usamos la función comprimir y pasamos el nombre del archivo como parámetro. Este sera guardado con el mismo nombre pero con extension .comp
# Definimos las matrices de cuantificación quant1 y quant2. Por default la compresión se hace usando quant1 pero opcionalmente se puede pasar una matriz de cuantizacion como parámetro si se desea usar otra
# Ademas de comprimir la imagen y guardar un archivo, la función comprimir devuelve las dimensiones de la imagen original. Podemos guardar estas medidas en una variable auxiliar
# Se puede observar que los archivos comprimidos tienen menor tamaño que los originales
# Para descomprimir un archivo usamos la función descomprimir pasándole como parámetro el nombre del archivo original pero con la extension .comp
# Opcionalmente, podemos pasarle las medidas de la imagen original si deseamos sacar el relleno de los bordes que se añadió para hacer la compresión. En caso de no pasarle este parámetro, la imagen descomprimida conserva el relleno
# La imagen comprimida se guarda en un archivo con el mismo nombre original mas el texto "_descomp" con formato .bmp
# Este ultimo archivo ya no tiene menor tamaño necesariamente pero sirve para ver que la descompresión se realiza correctamente
# Es necesario comprimir primero para después poder descomprimir
# El usuario solo maneja las funciones comprimir y descomprimir. El resto son funciones auxiliares de estas dos, cuyo nombre es declarativo sobre su funcionamiento
# Las imágenes que se cargan/comprimen/descomprimen están en la misma ubicación en que está este archivo
# Las siguientes lineas son ejemplos de como hacer la compresión/descompresión con las imágenes brindadas por la cátedra 

# La forma mas sencilla en que se puede comprimir/descomprimir una imagen (Sin sacar el relleno)
# comprimir("Meisje_met_de_parel.jpg")
# descomprimir("Meisje_met_de_parel.comp") 

# Si queremos sacar el relleno de los bordes
# medidas = comprimir("Meisje_met_de_parel.jpg")
# descomprimir("Meisje_met_de_parel.comp", medidas) 

# Si queremos usar otra matriz de cuantizacion
# comprimir("Meisje_met_de_parel.jpg",quant2)
# descomprimir("Meisje_met_de_parel.comp") 

# Otros ejemplos
# comprimir("paisaje.bmp")
# descomprimir("paisaje.comp")

# Otros ejemplos
# medidas = comprimir("paisaje.bmp")
# descomprimir("paisaje.comp",medidas)

# Otros ejemplos
# medidas = comprimir("paisaje.bmp", quant2)
# descomprimir("paisaje.comp",medidas)

# Otros ejemplos
# comprimir("bolitas.bmp")
# descomprimir("bolitas.comp")

# Otros ejemplos
# medidas = comprimir("bolitas.bmp")
# descomprimir("bolitas.comp", medidas)

# Otros ejemplos
# medidas = comprimir("bolitas.bmp",quant2)
# descomprimir("bolitas.comp", medidas)

import Pkg
Pkg.add("Images")
Pkg.add("FFTW")
Pkg.add("StatsBase")
using Images
using FFTW
using StatsBase

function rellenar(M)
	n,m = size(M)
	relleno_n = (16-n%16)%16
	relleno_m = (16-m%16)%16
	n2 = n+relleno_n
	m2 = m+relleno_m
	M2 = fill(RGB(0.,0.,0.),n2,m2)
	M2[relleno_n÷2+1:relleno_n÷2+n,relleno_m÷2+1:relleno_m÷2+m] = M
	return M2
end

function sacar_relleno(M2,medidas)
	n = medidas[1]
	m = medidas[2]
	relleno_n = (16-n%16)%16
	relleno_m = (16-m%16)%16
	n2 = n+relleno_n
	m2 = m+relleno_m
	M = M2[relleno_n÷2+1:relleno_n÷2+n,relleno_m÷2+1:relleno_m÷2+m] 
	return M
end

function reducir(M)
	n,m = size(M)
	M2 = Array{Float64}(undef, n÷2, m÷2)
	for i in 1:n÷2
		for j in 1:m÷2
			M2[i,j]=(M[2i-1,2j-1]+M[2i,2j-1]+M[2i-1,2j]+M[2i,2j])/4
		end
	end
	return M2
end

function expandir(M)
	n,m = size(M)
	M2 = Array{Float64}(undef, n*2, m*2)
	for i in 1:n*2
		for j in 1:m*2
			M2[i,j]= M[i÷2+i%2,j÷2+j%2]
		end
	end
	return M2
end

function RGB_a_YCbCr(im)
	im2 = YCbCr.(im)
	separados = channelview(im2)
	Y = separados[1,:,:]
	Cb = separados[2,:,:]
	Cr = separados[3,:,:]
	Cb2 = reducir(Cb)
	Cr2 = reducir(Cr)
	return Y.-128, Cb2.-128, Cr2.-128
end

function YCbCr_a_RGB(Y, Cb, Cr)
	Y2 = Y.+128
	Cb2 = Cb.+128
	Cr2 = Cr.+128
	return RGB.(colorview(YCbCr,Y2,expandir(Cb2),expandir(Cr2)))
end

function transformada_mat(M)
	n,m = size(M)
	for i in 1:8:n
		for j in 1:8:m
			dct!(@view M[i:i+7,j:j+7])
		end
	end
	return M
end

function transformada_mat_i(M)
	n,m = size(M)
	for i in 1:8:n
		for j in 1:8:m
			idct!(@view M[i:i+7,j:j+7])
		end
	end
	return M
end

function transformada_canales(Y, Cb, Cr)
	return transformada_mat(Y), transformada_mat(Cb), transformada_mat(Cr)
end

function transformada_canales_i(Yt,Cbt,Crt)
	return transformada_mat_i(Yt), transformada_mat_i(Cbt), transformada_mat_i(Crt)
end

function cuantizacion_mat(M,quant)
	n,m = size(M)
	M2 = Array{Int8}(undef, n, m)
	for i in 1:8:n
		for j in 1:8:m
			M2[i:i+7,j:j+7] = Int8.(round.(M[i:i+7,j:j+7]./quant))
		end
	end
	return M2
end

function cuantizacion_mat_i(M,quant)
	n,m = size(M)
	M2 = Array{Float64}(undef, n, m)
	for i in 1:8:n
		for j in 1:8:m
			M2[i:i+7,j:j+7] = (M[i:i+7,j:j+7].*quant)
		end
	end
	return M2
end

function cuantizacion_canales(Y,Cb,Cr,quant)
	return cuantizacion_mat(Y,quant), cuantizacion_mat(Cb,quant), cuantizacion_mat(Cr,quant)
end

function cuantizacion_canales_i(Y,Cb,Cr,quant)
	return cuantizacion_mat_i(Y,quant), cuantizacion_mat_i(Cb,quant), cuantizacion_mat_i(Cr,quant)
end

function zig_zag(M)
	N = size(M)[1]
	v = []
	for i in 1:N*2
		for j in 1:i
			if (i-j+1)>=1 && (i-j+1)<=N && (j)>=1 && (j)<=N
				if (i%2)==1
					push!(v,M[i-j+1,j])
				else 
					push!(v,M[j,i-j+1])
				end
			end
		end	
	end
	return v
end

function zig_zag_i(v)
	M = Array{Float64}(undef, 8, 8)
	N = size(M)[1]
	for i in 1:N*2
		for j in 1:i
			if (i-j+1)>=1 && (i-j+1)<=N && (j)>=1 && (j)<=N
				if (i%2)==1
					M[i-j+1,j] = popfirst!(v)
				else 
					M[j,i-j+1] = popfirst!(v)
				end
			end
		end	
	end
	return M
	
end

function matriz_a_vector(M)
	n,m = size(M)
	n2 = n÷8
	m2 = m÷8
	v = []
	for i in 1:n2
		for j in 1:m2
			vals,reps = rle(zig_zag(M[8i-7:8i,8j-7:8j]))
			push!(v,reps...)
			push!(v,vals...)
		end
	end
	return v
end

function vector_a_matriz(v,n,m,pos_0)
	M = Array{Float64}(undef, n, m)
	a=1
	b=1
	
	N = size(v)[1]
	p = 0
	j = pos_0
	i = pos_0
	while i <= N && a<=n && b<=m
		p += v[i]
		if p==64
			reps = v[j:i]
			vals = v[i+1:i+1+i-j]
			
			inv = inverse_rle(vals,Int.(reps))
			M_aux = zig_zag_i(inv)

			M[a:a+7,b:b+7] = M_aux
			b=b+8
			if b>=m+1
				b=1
				a=a+8
			end
			
			j = i+1+i-j+1
			i = j-1
			p = 0
		end
		i += 1
	end
	return M, i
end

function armar_tira(Y,Cb,Cr)
	return vcat(matriz_a_vector(Y),matriz_a_vector(Cb),matriz_a_vector(Cr))
end

function desarmar_tira(v,n,m)
	Y , pos_Cb = vector_a_matriz(v,n,m,1)
	Cb, pos_Cr = vector_a_matriz(v,n÷2,m÷2,pos_Cb)
	Cr, pos_final = vector_a_matriz(v,n÷2, m÷2, pos_Cr)
	
	return Y, Cb, Cr
end

function guardar(n, m, quant, v, nombre)
	io = open(nombre,"w")
	write(io,UInt16(n))
	write(io,UInt16(m))
	for i in 1:8
		for j in 1:8
			write(io, UInt8(quant[i,j]))
		end
	end
	for i in 1:size(v)[1]
		write(io,Int8(v[i]))
	end
	close(io)
end

function leer(archivo)
	io = open(archivo)
	n = read(io,UInt16)
	m = read(io,UInt16)
	quant = Array{Float64}(undef, 8, 8)
	
	for i in 1:8
		for j in 1:8
			quant[i,j] = read(io,UInt8)
		end
	end
	v=[]
	while !eof(io)
		x=read(io,Int8)
		push!(v,x)
	end
	close(io)

	return n, m, quant, v
end

function comprimir(archivo,quant=quant1)
	Im = load(archivo)
	n, m = size(Im)
	Im2 = rellenar(Im)
	n2, m2 = size(Im2)
	Y,Cb,Cr = RGB_a_YCbCr(Im2)
	Yt, Cbt, Crt = transformada_canales(Y,Cb,Cr)
	Yq, Cbq, Crq = cuantizacion_canales(Yt, Cbt, Crt, quant)
	v = armar_tira(Yq,Cbq,Crq)
	nombre_comprimido = split(archivo, ".")[1] * ".comp"
	guardar(n2,m2,quant, v, nombre_comprimido)
	return [n,m]
end

function descomprimir(archivo,medidas=[-1,-1])
	n2, m2, quant, v = leer(archivo)
	Yq, Cbq, Crq = desarmar_tira(v,n2,m2)
	Yt, Cbt, Crt = cuantizacion_canales_i(Yq, Cbq, Crq, quant)
	Y, Cb, Cr = transformada_canales_i(Yt, Cbt, Crt)
	Im_con_relleno = YCbCr_a_RGB(Y,Cb,Cr)
	if medidas != [-1,-1]
		Im_reconstruida = sacar_relleno(Im_con_relleno,medidas)
	else
		Im_reconstruida = Im_con_relleno
	end
	nombre_descomprimido = split(archivo, ".")[1] * "_descomp"* ".bmp"
	save(nombre_descomprimido,Im_reconstruida)
end

begin
	quant1=[16 11 10 16 24 40 51 61;
           12 12 14 19 26 58 60 55;
           14 13 16 24 40 57 69 56;
           14 17 22 29 51 87 80 62;
           18 22 37 56 68 109 103 77;
           24 35 55 64 81 104 113 92;
           49 64 78 87 103 121 120 101;
           72 92 95 98 112 100 103 99]

	quant2=[10 20 30 40 50 60 70 80;
            20 30 40 50 60 70 80 90;
            30 40 50 60 70 80 90 100;
            40 50 60 70 80 90 100 110;
            50 60 70 80 90 100 110 120;
            60 70 80 90 100 110 120 130;
            70 80 90 100 110 120 130 140;
            80 90 100 110 120 130 140 150]
end