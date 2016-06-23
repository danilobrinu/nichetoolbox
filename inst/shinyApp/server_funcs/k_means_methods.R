# K-means clustering

# K-means niche data input

niche_data_k_means <- reactive({
  if(!is.null(data_extraction()) && length(input$cluster_vars)>2){
    if(input$load_kmeas_vars){
      isolate({
        return(data_extraction()[,input$kmeans_vars])
      })
    }
    else
      return(NULL)
  }
  else
    return(NULL)
})


# Geographic data

geographic_data <- reactive({
  if(input$datasetM == "gbif_dat" && !is.null(data_gbif()))
    return(data_gbif())
  if(input$datasetM == "updata" && !is.null(data_user_clean()))
    return(data_user_clean())
  else
    return(NULL)
})

# Niche Groups may reflect local adaptations

kmeans_df <- reactive({
  if(!is.null(niche_data_k_means())){
    niche_data <- niche_data_k_means()
    level <- input$kmeans_level
    km <- kmeans(niche_data,centers=nclus,iter.max=100,trace=F,level=0.95)
    cluster <- km$cluster
    geo_dat <- data_to_extract()
    kmeans_data <- data.frame(geo_dat,cluser = cluster,niche_data)
    return(kmeans_data)
  }
  else
    return(NULL)
})


# Niche Groups may reflect local adaptations

kmeans_3d_plot <- reactive({
  if(!is.null(kmeans_df())){
    withProgress(message = 'Doing computations', value = 0, {
      niche_data <- niche_data_k_means()
      not_dup_niche_space <- !duplicated(niche_data)
      cluster_ids <- kmeans_df()$cluster[not_dup_niche_space]
      dat_clus <-  niche_data[not_dup_niche_space,c(input$x1,input$y1,input$z1)]
      vgrupo <-  geographic_data()[,input$vgrupo]
      vgrupo <- vgrupo[not_dup_niche_space]
      d_b1 <- na.omit(dat_clus)
      d_b1 <- data.frame(d_b1)

      cluster_3d(niche_data = d_b1,cluster_ids = cluster_ids,
                 vgrupo = vgrupo,x = input$x1,y = input$y1,
                 z = input$z1,alpha = input$alpha,ellips = input$ellips,
                 grupos=input$grupos,input$cex1,level=input$kmeans_level)
    })
  }
})

observe({
  if(!is.null(data_extraction()))
    updateSelectInput(session,"cluster_vars",choices = names(data_extraction())[1:3])
})