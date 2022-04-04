## code to prepare `invoice_line_item_test_data` dataset goes here
library(tibble)
library(usethis)

invoice_line_item_test_data <- tribble(
    ~id,
    ~service_identifier,
    ~service_type_code,
    ~service_instance_id,
    ~ctsi_study_id,
    ~name_of_service,
    ~other_system_invoicing_comments,
    ~cost_of_service,
    ~qty_provided,
    ~amount_due,
    ~fiscal_year,
    ~month_invoiced,
    ~pi_last_name,
    ~pi_first_name,
    ~pi_email,
    ~gatorlink,
    ~reason,
    ~status,
    ~created,
    ~updated,
    1,"1-6490",1,"6490",1919,"Action Tags Demo","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=6490",100,1,100,"2020-2021","June","Stoffs","Taryn","tls@ufl.edu","tls","New item to be invoiced","paid","2021-06-01T06:30:00Z","2021-06-01T06:30:00Z",
    2,"1-2345",1,"2345",1920,"My Cool Study","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=2345",100,1,100,"2020-2021","June","Chase","Pris","pris.chase@ufl.edu","pris.chase","New item to be invoiced","paid","2021-06-01T06:30:00Z","2021-07-15T12:30:00Z",
    3,"1-3456",1,"3456",2929,"Your Cool Study","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=3456",100,1,100,"2020-2021","June","Stoffs","Eunice","estoffs@ufl.edu","estoffs","New item to be invoiced","paid","2021-06-01T06:30:00Z","2021-07-03T14:50:00Z",
    4,"1-4567",1,"4567",3030,"YANCS","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=4567",100,1,100,"2020-2021","June","Zeitler","Joyce","zeitler@ufl.edu","zeitler","New item to be invoiced","paid","2021-06-01T06:30:00Z","2021-09-04T09:20:00Z",
    5,"3-jane@esu.edu",3,"jane@esu.edu",3333,"jane@esu.edu","Sponsor Gatorlink: pbc, PI Name: Tank McNamara",35,1,35,"2021-2022","July","McNamara","Tank","tank@ufl.edu","tank","New item to be invoiced","paid","2021-07-01T06:30:00Z","2021-07-14T14:20:00Z",
    6,"3-john@esu.edu",3,"john@esu.edu",3334,"john@esu.edu","Sponsor Gatorlink: pbc, PI Name: Tank McNamara",35,1,35,"2021-2022","July","McNamara","Tank","tank@ufl.edu","tank","New item to be invoiced","paid","2021-07-01T06:30:00Z","2021-07-14T14:20:00Z",
    7,"3-jane@esu.edu",3,"jane@esu.edu",3333,"jane@esu.edu","Sponsor Gatorlink: pbc, PI Name: Tank McNamara",35,1,35,"2021-2022","January","McNamara","Tank","tank@ufl.edu","tank","New item to be invoiced","paid","2022-01-01T06:30:00Z","2022-01-14T16:20:00Z",
    8,"3-john@esu.edu",3,"john@esu.edu",3334,"john@esu.edu","Sponsor Gatorlink: pbc, PI Name: Tank McNamara",35,1,35,"2021-2022","January","McNamara","Tank","tank@ufl.edu","tank","New item to be invoiced","paid","2022-01-01T06:30:00Z","2022-01-14T16:20:00Z",
    9,"3-jim@example.org",3,"jim@example.org",3335,"jim@example.org","Sponsor Gatorlink: cpb, PI Name: Christopher Barnes",35,1,35,"2021-2022","February","Barnes","Chris","cpb@ufl.edu","cpb","New item to be invoiced","paid","2022-02-01T06:30:00Z","2022-02-23T17:00:00Z",
    10,"5-6490",5,"6490",565656,"REDCap Mobile: Action Tags Demo","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/MobileApp/index.php?pid=6490",1000,1,1000,"2021-2022","March","Stoffs","Taryn","tls@ufl.edu","tls","New item to be invoiced","paid","2022-03-01T06:30:00Z","2022-03-09T11:11:00Z",
    11,"5-2345",5,"2345",787878,"REDCap Mobile: My Cool Study","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/MobileApp/index.php?pid=2345",1000,1,1000,"2021-2022","April","Chase","Pris","pris.chase@ufl.edu","pris.chase","New item to be invoiced","unreconciled","2022-04-01T06:30:00Z","2022-06-26T12:30:00Z",
    12,"1-6490",1,"6490",1919,"Action Tags Demo","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=6490",100,1,100,"2021-2022","June","Stoffs","Taryn","tls@ufl.edu","tls","New item to be invoiced","sent","2022-06-02T06:30:00Z","2022-06-02T06:30:00Z",
    13,"1-2345",1,"2345",1920,"My Cool Study","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=2345",100,1,100,"2021-2022","June","Chase","Pris","pris.chase@ufl.edu","pris.chase","New item to be invoiced","sent","2022-06-02T06:30:00Z","2022-06-02T06:30:00Z",
    14,"1-3456",1,"3456",2929,"Your Cool Study","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=3456",100,1,100,"2021-2022","June","Stoffs","Eunice","estoffs@ufl.edu","estoffs","New item to be invoiced","sent","2022-06-02T06:30:00Z","2022-06-02T06:30:00Z",
    15,"1-4567",1,"4567",3030,"YANCS","https://redcap.ctsi.ufl.edu/redcap/redcap_v11.3.4/index.php?pid=4567",100,1,100,"2021-2022","June","Zeitler","Joyce","zeitler@ufl.edu","zeitler","New item to be invoiced","sent","2022-06-02T06:30:00Z","2022-06-02T06:30:00Z"
)
usethis::use_data(invoice_line_item_test_data, overwrite = TRUE)
