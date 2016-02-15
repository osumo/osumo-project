shinyUI( pageWithSidebar(
  #tags$head(includeScript("www/lib/d3.v3.min.js")),
            
  headerPanel('iGPSe: Interactive Genomics Patient Stratification explorer'),
  sidebarPanel(
    h4("Upload Dataset "),
    width = 3,
    # file input button
    fileInput("mRNA","Upload the Gene expression profile"), # fileinput() function is used to get the file upload contorl option
    
    fileInput("miRNA","Upload the MicroRNA expression profile"),
    
    fileInput("clinical","Upload the Clinical profile"),
    
    tags$hr(),
    
    br(),
    
    actionButton("loadSampleData", "Use Sample Files"),
    
    p('If you want a sample .csv file to upload,',
      'you can first download the sample',
      a(href =  'data/mRNA.sample.csv', 'mRNA.sample.csv'), ', ',
      a(href = 'data/miRNA.sample.csv', 'miRNA.sample.csv'), ' and ',
      a(href = 'data/time.cencer.csv', 'time.cencer.csv' ),
      'files, and then try uploading them.')
  ),
  
  
  mainPanel(
    tabsetPanel(
      tabPanel("Data info",  
               fluidRow(
                 column(width = 3,
                        offset = 1,
                        style = "height:800px;background-color:#F0F8FF;",
                        h4("Gene expression "),
                        tags$hr(),
                        verbatimTextOutput("mRNA.info")
                 ),
                 column(width = 3,
                        offset = 1,
                        style = "height:800px;background-color:#F0F8FF;",
                        h4("microRNA"),
                        tags$hr(),
                        verbatimTextOutput("miRNA.info")
                 ),
                 column(width = 3,
                        offset = 1,
                        style = "height:800px;background-color:#F0F8FF;",
                        h4("Clinical "),
                        tags$hr(),
                        verbatimTextOutput("clinical.info")
                 )
               )
      ), 
      tabPanel("Clustering Analysis" ,
               fluidRow(
                 column(1),
                 column(4,
                        style = "height:800px;background-color:#F0F8FF;",
                        h4("mRNA Clustering"),
                        tags$hr(),
                        selectInput('Metric', 'Metric: ', metric.s),
                        selectInput('Algorithms', 'Algorithms: ', algorithm.s,
                                    selected=names(iris)[[2]]),
                        selectInput('mRNA_clusters_k', 'Number of clusters(k)', c(2:9),
                                    selected = 3),
                        actionButton("mRNACluster", "Run"),
                        plotOutput("mRNAheatmapplot")  
                 ),
                 column(1),
                 column(4,
                        style = "height:800px;background-color:#FFF0F5;",
                        h4("miRNA Clustering"),
                        tags$hr(),
                        selectInput('Metric', 'Metric: ', metric.s),
                        selectInput('Algorithms', 'Algorithms: ', algorithm.s,
                                    selected=names(iris)[[2]]),
                        selectInput('miRNA_clusters_k', 'Number of clusters(k)', c(2:9),
                                    selected = 3),
                        actionButton("miRNACluster", "Run"),
                        plotOutput("miRNAheatmapplot")  
                 )
               )
      ), 
      tabPanel("paralleset", 
               tags$div(style="margin:10px",
                        HTML(file_content("www/parallelSets.html"))
               ),
               plotOutput("clustering.info")
      )
    )
    
  )
))