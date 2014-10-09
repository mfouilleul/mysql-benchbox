<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <meta http-equiv="Content-type" content="text/html; charset=UTF-8" />
    <title>BenchBox</title>
    <link rel="stylesheet" href="css/bootstrap.css" />
    <link rel="stylesheet" href="css/style.css" />
    <link rel="icon" href="css/favicon.ico" />
    </head>
    <body>
        <div class="container">
            <h1 id="main_title">Bench<b>Box</b></h1>
            <div id="filter">
                <form role="form">
                    <div class="form-group">
                      <input type="text" class="form-control" id="searchInput" placeholder="Type To Filter">
                    </div>
                </form>
            </div>
            <div id="charts">
                <div class="row">
                    <div class="col-md-6">
                        <p><strong> Transactions/s </strong></p>
                        <canvas id="tps" class="graph" width="550" heigth="400"></canvas>
                    </div>
                    <div class="col-md-6">
                        <p><strong> Response Time (ms) </strong></p>
                        <canvas id="rt" class="graph" width="550" heigth="400"></canvas>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <p><strong> Reads/s </strong></p>
                        <canvas id="rds" class="graph" width="550" heigth="400"></canvas>
                    </div>
                    <div class="col-md-6">
                        <p><strong> Writes/s </strong></p>
                        <canvas id="wrs" class="graph" width="550" heigth="400"></canvas>
                    </div>
                </div>
            </div>
            <div id="context">
                <table id="context_table" class="table table-striped">
                    <thead>
                        <tr>
                            <th>
                                Info
                            </th>
                            <th>
                                Value
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </div>
            <div id="variables">
                <table id="variables_table" class="table table-striped">
                    <thead>
                        <tr>
                            <th>
                                Name
                            </th>
                            <th>
                                Value
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                    </tbody>
                </table>
            </div>
            <div id="list">
                <table id="files" class="table tablesorter">
                    <thead>
                        <tr>
                            <th>
                                Name
                            </th>
                            <th>
                                Date
                            </th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php
                            foreach (new DirectoryIterator('./json') as $file) {
                                if($file->isDot()) continue;
                                echo "<tr id='" . $file->getFileName() . "'>";
                                echo "<td class='filename'>" . $file->getFileName() . "</td>";
                                echo "<td>" . date('Y-m-d H:i:s',filemtime($file->getPathName())) . "</td>";
                                echo "</tr>";
                            }
                        ?>
                    </tbody>
                </table>
            </div>
        </div>
    
        <script type="text/javascript" src="js/jquery-2.1.1.min.js"></script>
        <script type="text/javascript" src="js/Chart.min.js"></script>
        <script type="text/javascript" src="js/bootstrap.min.js"></script>
        <script type="text/javascript" src="js/jquery.tablesorter.min.js"></script>
        <script type="text/javascript" src="js/scripts.js"></script>
    
    </body>
</html>
