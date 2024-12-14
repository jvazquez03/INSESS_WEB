library(jsonlite)

##################################################################################################################################
################################################################### IMPORTING DATA ############################################### 
##################################################################################################################################

args <- commandArgs(trailingOnly = TRUE)  

blocs <- args[1]
blocs <- gsub("^'|'$", "", blocs) 
blocs <- gsub("^\\[|\\]$", "", blocs) 
blocs <- unlist(strsplit(blocs, ",")) 
column_titles <- blocs[1]  
data_values <- blocs[-1] 
blocs <- data.frame(data_values, stringsAsFactors = FALSE)
colnames(blocs) <- column_titles  
  
preg <- args[2]
preg <- gsub("^'|'$", "", preg) 
preg <- gsub("^\\[|\\]$", "", preg)
preg <- strsplit(preg, "\\]\\[", perl = TRUE)[[1]]

# Procesar nombres de columnas
columns <- gsub("\\[|\\]", "", preg[1])
column_names <- strsplit(columns, ",")[[1]] 

# Procesar filas (si existen)
rows <- preg[-1]
if (length(rows) > 0) {
  rows <- lapply(rows, function(row) {
    strsplit(row, ",(?=(?:[^\\[]*\\[|\\w))", perl = TRUE)[[1]]
  }) 
  
  # Verificar que todas las filas tengan la misma longitud que las columnas
  lengths <- sapply(rows, length)
  if (any(lengths != length(column_names))) { 
    stop("El número de columnas en las filas no coincide con el número de nombres de columna")
  }
  
  # Construir dataframe con filas
  preg <- as.data.frame(do.call(rbind, rows), stringsAsFactors = FALSE)
} else {
  # Crear dataframe vacío si no hay filas
  preg <- as.data.frame(matrix(ncol = length(column_names), nrow = 0))
}
 

# Asignar nombres de columnas
colnames(preg) <- column_names 
 
  
metadata <- data.frame(NamesCOL = numeric(),
                       Eticol = numeric(),
                       Bloc = numeric(),
                       Nom_Bloc	= character(),
                       Inicial_Pregunta = character(),
                       Pregunta = character(),
                       Respostes = character(),
                       Columnes	= character(),
                       Rephrase	= character(),
                       Colcurt = character(),
                       Object	= character(),
                       PreguntaG= character(),
                       Tipus = character(),
                       PackIni = numeric(),
                       PackFi = numeric(),
                       nCols = numeric(),
                       nBlocs = numeric(),
                       TipusDescriptiva = character())	




diccionario <- list()
 
for (i in 1:nrow(blocs)) { 
  valor_fila <- as.character(blocs[i, ])
  diccionario[[valor_fila]] <- i
}  

calculate_param <- function(tipos, modalitats){
  nCols <- "NA"
  if (tipos == "Numerical" ) nCols <- length(modalitats)
  else if (tipos == "Simple Response") nCols <- length(modalitats)
  else if (tipos == "Multivalued List") nCols <- length(modalitats)
  else if (tipos == "Grid") nCols <- length(modalitats)
  else nCols <- length(modalitats)
  return (nCols)
}

new_data_row <- function(dataframe, new_row) { 
  columnas_df <- colnames(dataframe)
  col_new_row <- colnames(new_row)
  col_to_set <- setdiff(columnas_df, col_new_row)
  for (col in col_to_set) new_row[[col]] <- NA
  dataframe <- rbind(dataframe, new_row)
  return(dataframe)
}

create_nogrid_resp_df <- function(pregunta, Q_Reph, metadata, respostes, respReph, namesCol){  
  numNewRows <- length(respostes)  
  
  for (i in 1:numNewRows) { 
    new_row <- data.frame(Rephrase = respReph[i], Respostes = respostes[i],   
                          Object = "Modalitat", Eticol = namesCol)
    metadata <- new_data_row(metadata, new_row) 
  } 
  
  namesCol <<- namesCol + 1
  return(metadata)
}


create_grid_resp_df <- function(Q_id, pregunta, Q_Reph, metadata, respVect, colVect, colCurt, respReph, namesCol){
  numNewRows <- max(length(respVect), length(colVect)) 
  
  for (i in 1:numNewRows) { 
    if (length(colVect) < length(respVect)){ 
      if (i <= length(colVect)){  
        new_row <- data.frame(Inicial_Pregunta = Q_id, Rephrase = respReph[i], Respostes = respVect[i],
                              Columnes = colVect[i], Colcurt = colCurt[i], 
                              Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                              Object = "Modalitat", NamesCOL = namesCol)
      }
      else new_row <- data.frame(Inicial_Pregunta = Q_id, Rephrase = respReph[i], Respostes = respVect[i], 
                                 Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                                 Object = "Modalitat", NamesCOL = namesCol)
      namesCol <- namesCol + 1
    }
    else { 
      if (i <= length(respVect)){ 
        new_row <- data.frame(Inicial_Pregunta = Q_id, Rephrase = respReph[i], Respostes = respVect[i],
                              Columnes = colVect[i], Colcurt = colCurt[i], 
                              Pregunta = paste0(pregunta, ' [', respVect[i] ,']'), 
                              Object = "Modalitat", NamesCOL = namesCol)
        namesCol <- namesCol + 1
      }
      else new_row <- data.frame(Columnes = colVect[i], Colcurt = colCurt[i], Object = "Modalitat")
    }
    metadata <- new_data_row(metadata, new_row) 
  }
  
  namesCol <<- namesCol
  return(metadata)
}


##################################################################################################################################
################################################################### MAIN CODE ####################################################
##################################################################################################################################


initial_order <- colnames(metadata)
actBloc <- -1
namesCol <- 2
k0 <- -1
kf <- -1

if (nrow(preg) != 0) {
  for (i in 1:nrow(preg)) {
    
    Q <- preg[i, "Pregunta"]
    Q_Reph <- preg[i, "Pregunta.abreujada"]
    B <- preg[i, "Bloc"]
    Q_Type <- preg[i, "Tipo.de.pregunta"]
    Q_id <- preg[i, "Numero.de.Pregunta"]
    numBloc <- diccionario[[B]]
    
    if (numBloc != actBloc){
      new_row <- data.frame(Bloc = numBloc, Nom_Bloc = B, Object = "Bloc")
      metadata <- new_data_row(metadata, new_row)
      actBloc <- numBloc
    }
    
    if (Q_Type == "Open") {
      tiposDescriptiva <- "NA" 
      new_row <- data.frame(Inicial_Pregunta = Q_id, Rephrase = paste0(Q_id, ' .', Q_Reph), 
                            Pregunta = Q, Tipus = Q_Type, Object = "Qüestio", 
                            PreguntaG = Q, TipusDescriptiva = tiposDescriptiva)
      
      metadata <- new_data_row(metadata, new_row)
    }
    else if (Q_Type == "Simple Response") {
      new_row <- data.frame(Object="Separador")
      metadata <- new_data_row(metadata, new_row)
      
      respostes <- preg[i, "Valores"] 
      respostes <- gsub("^\\[|\\]$", "", respostes)
      respostes <- strsplit(respostes, ";")[[1]] 
      
      respReph <- preg[i, "Abreviación.de.valores"]
      respReph <- gsub("^\\[|\\]$", "", respReph)
      respReph <- strsplit(respReph, ";")[[1]]
      
      
      tiposDescriptiva <- "b"
      new_row <- data.frame(Inicial_Pregunta = Q_id,  Rephrase = paste0(Q_id, '.', Q_Reph), 
                            Pregunta = Q, Tipus = Q_Type, Object = "Qüestio", TipusDescriptiva = tiposDescriptiva,
                            NamesCOL = namesCol)
      metadata <- new_data_row(metadata, new_row)
      
      metadata <- create_nogrid_resp_df(pregunta, Q_Reph, metadata, respostes, respReph, namesCol)
    }
    
    else if (Q_Type == "Grid") {
      respostes <- preg[i, "Valores"] 
      respostes <- gsub("^\\[|\\]$", "", respostes) 
      respostes <- strsplit(respostes, ";")[[1]]
      
      columnes <- preg[i, "Puntuaciones"] 
      columnes <- gsub("^\\[|\\]$", "", columnes)
      columnes <- strsplit(columnes, ";")[[1]]
      
      respReph <- preg[i, "Abreviación.de.valores"]
      respReph <- gsub("^\\[|\\]$", "", respReph)
      respReph <- strsplit(respReph, ";")[[1]]
      
      colCurt <- preg[i, "Abreviación.de.puntuaciones"] 
      colCurt <- gsub("^\\[|\\]$", "", colCurt)
      colCurt <- strsplit(colCurt, ";")[[1]]
      
      tiposDescriptiva <- "a "
      
      nCols <- calculate_param(Q_Type, columnes) 
      k0 <- namesCol
      kf <- k0 + max(length(respostes), length(columnes))  
      
      new_row <- data.frame(Inicial_Pregunta = Q_id, Rephrase = paste0(Q_id, ' .', Q_Reph), 
                            Pregunta = Q, Tipus = Q_Type, Object = "Qüestio", 
                            PreguntaG = Q, nCols = nCols, TipusDescriptiva = tiposDescriptiva, PackIni = k0,
                            PackFi = kf)
      
      metadata <- new_data_row(metadata, new_row) 
      new_row <- data.frame(Respostes = "Files", Columnes = "Columnes", Object = "Separador") 
      metadata <- new_data_row(metadata, new_row)
      
      metadata <- create_grid_resp_df(Q_id, Q, Q_Reph, metadata, respostes, columnes, colCurt, respReph, namesCol)
    }
    
    else if (tipos == "Numerical") { 
      respostes <- preg[i, "Valores"] 
      respostes <- gsub("^\\[|\\]$", respostes)
      respostes <- strsplit(respostes, ";")[[1]] 
      
      respReph <- preg[i, "Abreviación.de.valores"]
      respReph <- gsub("^\\[|\\]$", respReph)
      respReph <- strsplit(respReph, ";")[[1]]
      
      respVect <- paste(as.character(respostes), "-", as.character(respReph))
      
      tiposDescriptiva <- "b"
      
      new_row <- data.frame(Inicial_Pregunta = Q_id,  Rephrase = paste0(Q_id, '.', Q_Reph), 
                            Pregunta = Q, Tipus = Q_Type, Object = "Qüestio", TipusDescriptiva = tiposDescriptiva,
                            NamesCOL = namesCol)
      metadata <- new_data_row(metadata, new_row)
      
      metadata <- create_nogrid_resp_df(Q, Q_Reph, metadata, respostes, respReph, namesCol)
      
    }
    
  }
}

metadata <- metadata[, initial_order]  
 
metadata_json <- toJSON(metadata, na = "null", pretty = TRUE)
cat(metadata_json)

