
source("server_funcs/data_gbif.R",local = T)
source("server_funcs/dynamicMapMethods.R",local = T)
source("server_funcs/niche_layers_extract.R",local = T)
source("server_funcs/niche_space_visualizations.R",local = T)
source("server_funcs/k_means_methods.R",local = T)
source("server_funcs/correlation_methods.R",local = T)
source("server_funcs/bioclim_methods.R",local = T)
source("helpers/ellipsoid_3D_plot.R",local = T)
source("helpers/pROC.R",local = T)
source("server_funcs/ellipsoid_methods.R",local = T)
source("server_funcs/model_proj_methods.R",local = T)
source("server_funcs/partial_roc_methods.R",local = T)
source("server_funcs/binary_map_methods.R",local =T)
source("server_funcs/maxent_methods.R",local =T)
source("server_funcs/maxent_methods_mlayers.R",local =T)
observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$ras_layers_directory
  },
  handlerExpr = {
    if (input$ras_layers_directory > 0) {
      # condition prevents handler execution on initial app launch

      # launch the directory selection dialog with initial path read from the widget
      path = choose.dir(default = readDirectoryInput(session, 'ras_layers_directory'))

      # update the widget value
      updateDirectoryInput(session, 'ras_layers_directory', value = path)

    }
  }
)



observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$wf_directory
  },
  handlerExpr = {
    if (input$wf_directory > 0) {
      # condition prevents handler execution on initial app launch

      # launch the directory selection dialog with initial path read from the widget
      path = choose.dir(default = readDirectoryInput(session, 'wf_directory'))

      # update the widget value
      updateDirectoryInput(session, 'wf_directory', value = path)

    }
  }
)

# --------------------------------------------------------
# Save polygon to directory

observeEvent(
  ignoreNULL = TRUE,
  eventExpr = {
    input$poly_dir
  },
  handlerExpr = {
    if (input$poly_dir > 0) {
      # condition prevents handler execution on initial app launch

      # launch the directory selection dialog with initial path read from the widget
      path = choose.dir(default = readDirectoryInput(session, 'poly_dir'))

      # update the widget value
      updateDirectoryInput(session, 'poly_dir', value = path)

    }
  }
)


# Raster layer directory
rasterLayersDir <- reactive({
  path <- readDirectoryInput(session, 'ras_layers_directory')
  if(length(path)>0L)
    return(path)
  else
    return(NULL)
})

# Workflow directory
workflowDir <- reactive({
  path <- readDirectoryInput(session, 'wf_directory')
  if(length(path)>0L)
    return(path)
  else
    return(NULL)
})

# User raster (niche) layers

rasterLayers <- reactive({
  layers_dir <- rasterLayersDir()
  input$loadNicheLayers
  isolate({
    if(input$loadNicheLayers > 0 && length(layers_dir) > 0L)
      return(rlayers_ntb(layers_dir))
    else
      return(NULL)
  })
})

# Polygon directory
poly_dir <- reactive({
  path <- readDirectoryInput(session, 'poly_dir')
  if(length(path)>0L)
    return(path)
  else
    return(NULL)
})
# Shape layers in directory

layers_shp <- reactive({
  if(!is.null(poly_dir())){
    layersDir <- list.files(poly_dir(),pattern = "*.shp$",full.names = F)
    layers <- lapply(layersDir,
                     function(x)
                       str_extract_all(string = x,
                                       pattern = "([A-z]|[:digit:])+[^.\\shp]")[[1]])
    layers <- unlist(layers)
    layers <- c("Select a layer",layers)
    return(layers)
  }
  else
    return()
})

observe({
  if(!is.null(layers_shp())){
    updateSelectInput(session,inputId = "poly_files",
                      choices =layers_shp() , selected = "Select a layer")
  }
})

# Read polygons

myPolygon <- reactive({
  # Create polygon using leaflet maps
  if(!is.null(input$geojson_coords)){
    if(input$define_M == 1 && input$poly_from ==1){
      map <- readOGR(input$geojson_coords,"OGRGeoJSON")
      return(map)
    }
  }
  # Read polygon from user file
  if(input$define_M == 1 && input$poly_from ==0 && !is.null(poly_dir()) &&  input$poly_files != "Select a layer"){
    map <- readOGR(dsn = poly_dir(),layer = input$poly_files)
    return(map)
  }
  else
    return(NULL)

})





# -----------------------------------------------------------------
# Saving workflow
# -----------------------------------------------------------------



# -----------------------------------------------------------------------
# Observer for writing to the Workflow geographic data report
# ---------------------------------------------------------------------

observeEvent(input$saveState, {


  if(nchar(workflowDir()) > 0L){

    # Create a directory for OCC data.
    data_dir_path <- paste0(workflowDir(),"NicheToolBox_OccData")
    if(!dir.exists(data_dir_path))
      dir.create(data_dir_path)
    # Create a directory for workflow report
    wf_dir_path <- paste0(workflowDir(),"NicheToolBox_workflowReport")
    if(!dir.exists(wf_dir_path))
      dir.create(wf_dir_path)

    # Animated map of GBIF records

    anifile <- paste0(tempdir(),"/",temGBIF())
    anima_save <- paste0(wf_dir_path,"/",input$genus,"_",
                         input$species,"_animation.gif")

    if(file.exists(anifile)) file.copy(anifile, anima_save)

    #------------------------------------------------------------
    # NicheToolBox data report
    #------------------------------------------------------------

    # Path to report source

    report_path <- system.file("shinyApp/ntb_report/data_report.Rmd",
                                package = "nichetoolbox")

    mchart_path <- system.file("shinyApp/ntb_report/MotChartInstructions.Rmd",
                               package = "nichetoolbox")

    # save HTML path

    report_save <- paste0(wf_dir_path,"/","data_report.html")
    # save MotionChart display instructions
    mchart_save <- paste0(wf_dir_path,"/","DisplayMotionChartIns.html")

    # Compile workflow report

    render(input = report_path,
           output_format = html_document(pandoc_args = c("+RTS", "-K64m","-RTS"),
                                         highlight="haddock",
                                         toc = TRUE,theme = "readable"),
           output_file = report_save)

    # Compile Motion Chart instructions

    render(input = mchart_path,
           output_format = html_document(pandoc_args = c("+RTS", "-K64m","-RTS"),
                                         highlight="haddock",
                                         toc = TRUE,theme = "readable"),
           output_file = mchart_save)

    # Save raw GBIF data (from GBIF data search)
    if(!is.null(data_gbif_search())){
      gbif_file_raw <- paste0(data_dir_path,"/",
                              input$genus,"_",
                              input$species,"GBIF_raw_data",".csv")
      write.csv(data_gbif_search(),gbif_file_raw,row.names = FALSE)


    }
    # Save cleaned GBIF data (from GBIF data search)
    if(!is.null(data_gbif_search())){
      gbif_file_clean <- paste0(data_dir_path,"/",
                                input$genus,"_",
                                input$species,
                                "GBIF_cleaned_data",".csv")
      write.csv(data_gbif(),gbif_file_clean,row.names = FALSE)
    }

    # Save GBIF data from dynamic map (no polygon)
    if(!is.null(dataDynamic()) && input$dataset_dynMap == "gbif_dataset"){
      gbif_file_clean_dynamic <- paste0(data_dir_path,"/",
                                        input$genus,"_",
                                        input$species,
                                        "GBIF_clean_dynamic_data",".csv")
      write.csv(dataDynamic(),gbif_file_clean_dynamic,row.names = FALSE)
    }
    # Save GBIF data from dynamic map (in polygon)
    if(!is.null(data_poly()) && input$dataset_dynMap == "gbif_dataset"){
      gbif_file_clean_dynamic_poly <- paste0(data_dir_path,"/",
                                             input$genus,"_",
                                             input$species,
                                             "GBIF_clean_Polygon_dynamic_data",
                                             ".csv")
      write.csv(data_poly(),gbif_file_clean_dynamic_poly,row.names = FALSE)
    }




    # Save raw user data (from user data)

    if(!is.null(data_user())){
      user_file_raw <- paste0(data_dir_path,"/",
                              "user_raw_data",".csv")
      write.csv(data_user(),user_file_raw,row.names = FALSE)
    }

    # Save cleaned user data (from user data)

    if(!is.null(data_user_clean())){
      user_file_clean <- paste0(data_dir_path,"/",
                                "user_cleaned_data",".csv")
      write.csv(data_user_clean(),user_file_clean,row.names = FALSE)
    }
    # Save user data from dynamic map (no polygon)
    if(!is.null(dataDynamic()) && input$dataset_dynMap == "user_dataset"){
      user_file_clean_dynamic <- paste0(data_dir_path,"/",
                                        "user_clean_dynamic_data",".csv")
      write.csv(dataDynamic(),user_file_clean_dynamic,row.names = FALSE)
    }
    # Save GBIF data from dynamic map (in polygon)
    if(!is.null(data_poly()) && input$dataset_dynMap == "user_dataset"){
      user_file_clean_dynamic_poly <- paste0(data_dir_path,"/",
                                             "user_clean_Polygon_dynamic_data",
                                             ".csv")
      write.csv(data_poly(),user_file_clean_dynamic_poly,row.names = FALSE)
    }

    # Save polygon
    if(!is.null(myPolygon())){
      file_dir <- paste0(data_dir_path,"M_Shapefiles_",input$dataset_dynMap)
      if(!dir.exists(file_dir))
        dir.create(file_dir)
      poly_name <- input$polygon_name
      if(length(poly_name)<1)
        poly_name <- paste0("dynMpolygon_ntb",sample(1:1000,1))
      poly_name_ext <- paste0(poly_name,".shp")
      #if(poly_name_ext %in% list.files(file_dir)){
      #  poly_name <- paste0(poly_name,"B_RandNUM",sample(1:1000,1))
      #}
      writeOGR(myPolygon(), file_dir, poly_name,"_",input$dataset_dynMap, driver="ESRI Shapefile",overwrite_layer = T)

    }

  }
})


# -----------------------------------------------------------------------
# Observer for writing to the Workflow: Niche data report
# ---------------------------------------------------------------------

observeEvent(input$saveState, {
  niche_data <- data_extraction()
  if(nchar(workflowDir()) > 0L && !is.null(niche_data)){
    # Create a directory for niche data.
    niche_dir_path <- paste0(workflowDir(),"NicheToolBox_NicheData")
    if(!dir.exists(niche_dir_path))
      dir.create(niche_dir_path)
    # Create a directory for workflow report
    wf_dir_path <- paste0(workflowDir(),"NicheToolBox_workflowReport")
    if(!dir.exists(wf_dir_path))
      dir.create(wf_dir_path)


    #------------------------------------------------------------
    # NicheToolBox niche data report
    #------------------------------------------------------------

    # Path to report source

    niche_data_report_path <- system.file("shinyApp/ntb_report/niche_data_report.Rmd",
                                          package = "nichetoolbox")

    # save HTML path

    niche_data_report_save <- paste0(wf_dir_path,"/","niche_data_report.html")

    render(input = niche_data_report_path,
           output_format = html_document(pandoc_args = c("+RTS", "-K64m","-RTS"),
                                         highlight="haddock",
                                         toc = TRUE,theme = "readable"),
           output_file = niche_data_report_save)





  # Save data extraction

  if(!is.null(niche_data())){

    niche_data <- niche_data()
    ifelse(input$datasetM== "gbif_dat",data <- "GBIF_data", data <- "User_data")
    ifelse(input$extracted_area== "all_area",
           raster_data <- "All_raster_area",raster_data <- "M_polygon_area")

    write.csv(niche_data, paste0(niche_dir_path,
                                   "/niche_",data,"_",raster_data,".csv"),
              row.names = FALSE)
    if(!is.null(kmeans_df()))
      write.csv(kmeans_df(), paste0(niche_dir_path,
                                   "/niche_",data,"_kmeansCluster.csv"),
                row.names = FALSE)

    if(!is.null(corr_table())){
      write.csv(corr_table(), paste0(niche_dir_path,
                                    "/niche_",data,"_corretable.csv"),
                row.names = FALSE)

      niche_dir_path <- paste0(workflowDir(),"NicheToolBox_NicheData")
      save_corfind <- paste0(niche_dir_path,"/niche_correlationfinder.txt")
      corr_finder <- summs_corr_var()$cor_vars_summary
      capture.output(print(corr_finder),file=save_corfind)

    }

  }

}
})


