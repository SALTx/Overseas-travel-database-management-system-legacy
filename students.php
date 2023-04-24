<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <?php
    include "partials/imports.php";
    include "partials/helpers.php";
    ?>
    <title>Students | OTDBMS</title>
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

    <section>
        <h2>Table of students</h2>
        <table>
            <tr>
                <th>Admin number</th>
                <th>Name</th>
                <th>Admission year</th>
                <th>Gender</th>
                <th>Birthday</th>
                <th>Citizenship status</th>
                <th>diploma</th>
                <th>PEM name</th>
                <?php if ($admin) {
                    echo "<th>Actions</th>";
                } ?>
            </tr>
            <?php
            //display a list of students from the students table
            $sql = "SELECT * FROM students";
            $result = $connection->query($sql);
            while ($row = $result->fetch_assoc()) {
                echo "<tr>";
                echo "<td>" . $row["adminNumber"] . "</td>";
                echo "<td>" . $row["name"] . "</td>";
                echo "<td>" . $row["admissionYear"] . "</td>";
                echo "<td>" . $row["gender"] . "</td>";
                echo "<td>" . $row["birthday"] . "</td>";
                echo "<td>" . $row["citizenshipStatus"] . "</td>";
                echo "<td>" . $row["diploma"] . "</td>";
                echo "<td>" . $row["pemName"] . "</td>";
                if ($admin) {
                    echo "<td class='tableActions'>";
                    echo "<a href='delete.php?table=students&id=" . $row["adminNumber"] . "'><i class='fa-solid fa-trash' style='color:Maroon'></i></a>";
                    echo "<a href='edit.php?table=students&id=" . $row["adminNumber"] . "'><i class='fa-solid fa-pen-to-square' style='color:darkgreen'></i></i></a>";
                    echo "</td>";
                }
                echo "</tr>";
            }
            //if admin make an additional row for adding a new student
            if ($admin) {
                echo "<tr>";
                echo "<form action='add.php' method='post'>";
                echo "<td><input type='text' name='adminNumber' placeholder='Admin number' required></td>";
                echo "<td><input type='text' name='name' placeholder='Name' required></td>";
                echo "<td><input type='number' name='admissionYear' placeholder='Admission Year' required></td>";
                echo "<td>";
                $gender_values = get_enum_values($connection, "students", "gender");
                echo "<select name='gender' id='gender' required>";
                foreach ($gender_values as $value) {
                    echo "<option value='$value'>$value</option>";
                }
                echo "</select>";
                echo "</td>";
                echo "<td><input type='date' name='birthday' required></td>";
                echo "<td>";
                $citizenship_values = get_enum_values($connection, "students", "citizenshipStatus");
                echo "<select name='citizenshipStatus' id='citizenshipStatus' placeholder='Citizenship status' required>";
                foreach ($citizenship_values as $value) {
                    echo "<option value='$value'>$value</option>";
                }
                echo "</select>";
                echo "</td>";
                echo "<td><input type='text' name='diploma' placeholder='Diploma'></td>";
                echo "<td><input type='text' name='pemName' placeholder='PEM name' required></td>";
                echo "<td class='tableActions'>
                    <input type='hidden' value='students' name='table'>
                    <button type='submit'><i class='fa-solid fa-plus'></i></button>
                    </td>";
                echo "</form>";
                echo "</tr>";
            }
            ?>
        </table>
    </section>

    <?php include 'partials/footer.php'; ?>
</body>

</html>