<?php
    $strFile  = time() . '.jpg';
    $strInput = file_get_contents("php://input");
    if ($strInput) {
        file_put_contents(getcwd() . '/shoots/' . $strFile, $strInput);
        return $strFile;
    }
    return FALSE;
?>
