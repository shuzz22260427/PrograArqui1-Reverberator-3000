import simpleaudio as sa
import soundfile


# Esta funcion reproduce el sonido de archivos sin ecos
def playSong(file_archivo):
    wave_obj = sa.WaveObject.from_wave_file(file_archivo + ".wav")
    play_obj = wave_obj.play()
    play_obj.wait_done()  # Se espera a que el audio termine de sonar para cerrarse

# Esta funcion reproduce el sonido de archivos con ecos
def playEcoSong(file_archivo):
    wave_obj = sa.WaveObject.from_wave_file(file_archivo + "_eco.wav")
    play_obj = wave_obj.play()
    play_obj.wait_done()  # Se espera a que el audio termine de sonar para cerrarse

# Rellena el numero con los ceros que necesite a la derecha
def ponerCerosDerecha(numero, cantidad):
    resultado = numero
    while cantidad != 0:
        resultado += "0"
        cantidad -= 1
    return resultado

# Rellena el numero con los ceros que necesite a la derecha
def ponerCerosIzquierda(numero, cantidad):
    resultado = numero
    while cantidad != 0:
        resultado = "0" + resultado
        cantidad -= 1
    return resultado


# Resive un numero binario y a traves del algoritmo de conversion lo pasa a float
def binarioAFloat(numero_binario):
    result = 0
    exponente = 1
    for i in range (len(numero_binario)):
        msb = int(numero_binario[i])
        if msb != 1:
            pass
        else:
            result += 1 / (2**exponente)
        exponente += 1
    return result


    


#La funcion inversa de la binari to float, usa el rango del numero para crear un binario, en forma de string
def floatABinario(num):
    lista_res = []
    for x in range(8):
        act_num = num * 2
        act_int = int(act_num)
        temp = str(act_int)
        lista_res.append(temp)
        
        temp2 = abs(act_num)
        temp3 = abs(act_int)
        float_rest = abs(temp2 - temp3)
        num = float_rest

    result = ""
    for i in lista_res:
        result +=i
    return result



# Funcion que pasa el archivo de salida de ensamblador hasta audio
# Recibe el archivo de entrada de dos formas, uno para leer el auio y otro para escribirlo
def texto_sonido(file_name, file_namewav, sample_rate, audio_bits):
    dobleBits = 2 * audio_bits
    
    #Abre el archivo
    with open(file_name , "r") as entrada_text:
        lista_sonido = []
        while True:
            # Lee linea por linea hasta el final del archivo
            linea_actual = entrada_text.readline()
            if linea_actual == "":
                break # Terminar cuando se lea todo el archivo

            # Se convierte el numero a binario y se le quita el salto de linea
            numero_binario = linea_actual.replace('\n', '')

            # Se hace la conversion a entero
            numero_binario_int = int(numero_binario, 2)
            num = 0
            if numero_binario_int != 0:

                # Se obtiene el bit de signo para comprobarlo
                bit_de_signo = numero_binario[0]

                # Revisa si debe entrar a complemento 2 y meterle ceros a rellenar el numero
                if bit_de_signo == "1":
                    numero_binario = complementeADos(numero_binario, audio_bits)
                    numero_binario = ponerCerosIzquierda(numero_binario, (dobleBits - len(numero_binario)))

                # Obtiene los primeros 8 bits y los ultimos 8 bits
                bits_enteros = numero_binario[1:audio_bits]
                bits_flotantes = numero_binario[audio_bits:]

                # Se vuelve a armar el numero final
                numero_entero = int(bits_enteros, 2)
                numero_flotante = binarioAFloat(bits_flotantes)
                num = numero_entero + numero_flotante

                # Se revisa de nuevo si el numero era negativo para cambiarle el signo al resultado final
                if bit_de_signo == "1":
                    num = num * -1

            # Se agrega a la lista de numeros que van a ser el wav
            lista_sonido.append(num)

        # Escribe el archivo .wav
        soundfile.write(file_namewav + ".wav", lista_sonido, sample_rate)


# Calcula el complemento 2 de un numero usando un xor
def complementeADos(num, bits):
    num = int (num,2)
    bits = bits * 2 #Sacar 16 bits
    xor = ""
    cont = bits
    if num == 0:
        return '0'
    else:
        while cont > 0:
            xor += "1"
            cont -= 1
    resxor = int(xor,2) ^ num # Xor en python con el entero
    pre_result = resxor + 1
    result = bin(pre_result).replace("0b", "") #Esto es para quitarle el 0b que tiene el binario en python
    return result

# Funcion que saca los numeros en binario y los deja limpios. COnversion int a binario
def binConverter(num):
    result = bin(num).replace("0b","")
    return result


# Funcion que agarra el audio y lo convierte en el txt que recibira el ensamblador. Recibe 2, uno para leer el sonido y otro para decirle como debe ser
# La salida del texto en el forma de lectura del txx de ensamblador
def wav_to_txt(file_name, file_namesound, audio_bits):
    # Lee el sonido en el formato que se le dijo con file_name
    y, fs = soundfile.read(file_name + ".wav")

    with open(file_namesound , "w") as texto_final:
        for i in y:

            #Maneja la parte entera
            positivo = abs(i)
            parte_entera = int(positivo)
            entero_binario = binConverter(parte_entera)
            entero_bits = audio_bits - len(entero_binario)
            entero_binario = ponerCerosIzquierda( entero_binario, entero_bits)

            #Maneja la parte decimal
            temp1 = abs(i)
            temp2 = abs(parte_entera)
            punto_decimal = abs(temp1 - temp2)
            punto_decimal_binario = floatABinario(punto_decimal)
            punto_decimal_bits = audio_bits - len(punto_decimal_binario)
            punto_decimal_binario = ponerCerosDerecha(punto_decimal_binario, punto_decimal_bits)

            binario_final = entero_binario + punto_decimal_binario

            #Revisa si debe meterle complemento 2 al numero
            if int(binario_final,2) != 0 and i < 0:
                binario_final = complementeADos(binario_final, audio_bits)
            
            # Guarda el archivo final en Binario
            texto_final.write(binario_final + "\n")
            
