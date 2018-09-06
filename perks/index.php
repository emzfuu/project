<?php
echo "Hello this is the VR tickets <br>";

$servername = "localhost";
$username = "root";
$password = "123456789";
$dbname = "test";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$sql = "SELECT id, ticket_number, request_type FROM tbl_muse_week7_copy";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // output data of each row
    while($row = $result->fetch_assoc()) {
        echo "id: " . $row["id"]. " - ticket_number: " . $row["ticket_number"]. " request_type: " . $row["request_type"]. "<br>";
    }
} else {
    echo "0 results";
}

$conn->close();
?>
