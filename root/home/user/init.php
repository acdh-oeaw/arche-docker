<?php
sleep(5);
$pdo = new PDO('pgsql:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$schemaExists = $pdo->query("SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND tablename = 'resources'")->fetchColumn() === 1;
if (!$schemaExists) {
    $schemaFile = escapeshellarg('/home/user/acdh-repo/dbschema/db_schema.sql');
    system('/usr/bin/psql -f ' . $schemaFile);
}
// TODO adjusting config.yaml according to getenv() settings

