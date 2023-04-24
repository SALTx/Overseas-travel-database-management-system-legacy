<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OTDBMS | Home</title>
    <?php include 'partials/imports.php'; ?>
    <?php include 'partials/helpers.php'; ?>
</head>

<body>
    <?php
    session_start();

    if (!isset($_SESSION['username'])) {
        header('Location: login.php');
        exit();
    }

    $admin = false;
    if ($_SESSION['userType'] == 'Admin') {
        $admin = true;
    }

    $connection = connect_to_db();
    ?>
    <?php include 'partials/nav.php'; ?>

    <!-- Retrieve Students, the number of trips theyve been on, and the number of trips of which were in ACI countries -->
    <?php
    echo "<script>";
    $sql = "SELECT students.name, COUNT(trips.studentAdminNumber) AS total_trips, SUM(CASE WHEN overseasProgrammes.aciCountry = 1 THEN 1 ELSE 0 END) AS aci_trips  FROM students  LEFT JOIN trips ON students.adminNumber = trips.studentAdminNumber  LEFT JOIN overseasProgrammes ON trips.programmeId = overseasProgrammes.programmeId  GROUP BY students.adminNumber;";
    $result = $connection->query($sql);

    echo "students = []; tripCount=[]; aciTripCount=[];";

    while ($row = $result->fetch_assoc()) {
        echo "students.push('" . $row["name"] . "');";
        echo "tripCount.push('" . $row["total_trips"] . "');";
        echo "aciTripCount.push('" . $row["aci_trips"] . "');";
    }
    echo "</script>";
    ?>

    <div>
        <canvas id="myChart" style="position: relative; height:40vh; width:80vw"></canvas>
    </div>

    <h1>Overseas Travel Database prototype</h1>

    <!-- Table displaying overseas records -->
    <section id="overseasRecords">
        <h2>Records of student overseas travel</h2>
        <table>
            <tr>
                <th>Student name</th>
                <th>Admin Number</th>
                <th>Country visited</th>
                <th>Start date</th>
                <th>End date</th>
                <th>ACI Country</th>
                <?php if ($admin) {
                    echo "<th>Delete</th>";
                } ?>
            </tr>
            <?php
            //display a list of records of student who travelled overseas from the trips table
            $sql = "SELECT students.name, students.adminNumber, overseasProgrammes.country, overseasProgrammes.startDate, overseasProgrammes.endDate, overseasProgrammes.aciCountry, trips.tripId
                            FROM trips
                            JOIN students ON students.adminNumber = trips.studentAdminNumber
                            JOIN overseasProgrammes ON overseasProgrammes.programmeId = trips.programmeId";
            $result = $connection->query($sql);
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row["name"] . "</td>";
                echo "<td>" . $row["adminNumber"] . "</td>";
                echo "<td>" . $row["country"] . "</td>";
                echo "<td>" . $row["startDate"] . "</td>";
                echo "<td>" . $row["endDate"] . "</td>";
                //if aciCountry is true display yes, else display no
                if ($row["aciCountry"] == 1) {
                    echo "<td>Yes</td>";
                } else {
                    echo "<td>No</td>";
                }
                if ($admin) {
                    echo "<td><a href='delete.php?table=trips&id=" . $row["tripId"] . "'>Delete</a></td>";
                }
                echo "</tr>";
            }
            ?>
        </table>
    </section>
    <?php include 'partials/footer.php'; ?>

    <!-- script to load values into chart on canvas -->
    <script>
        const ctx = document.getElementById('myChart');

        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: students,
                datasets: [{
                    label: 'Number of overseas trips',
                    data: tripCount,
                    borderWidth: 0.5
                }, {
                    label: 'Number of trips to ACI countries',
                    data: aciTripCount,
                    borderWidth: 0.5
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            },
            options: {
                scales: {
                    x: {
                        title: {
                            display: true,
                            text: "Students"
                        }
                    },
                    y: {
                        title: {
                            display: true,
                            text: "Number of trips",
                        },
                        min: 0,
                        max: 5,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });
    </script>
</body>

</html>