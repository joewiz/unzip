xquery version "3.0";

(:~
 : A module for unzipping files stored in the database
 :
 : @author Joe Wicentowski
 :)

module namespace unzip = "http://joewiz.org/ns/xquery/unzip";

import module namespace compression = "http://exist-db.org/xquery/compression";
import module namespace functx = "http://www.functx.com"; 
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
 
(: Helper function of unzip:mkcol() :)
declare %private function unzip:mkcol-recursive($collection, $components) as xs:string* {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xmldb:create-collection($collection, $components[1]),
            if ($components[2]) then 
                unzip:mkcol-recursive($newColl, subsequence($components, 2))
            else ()
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare %private function unzip:mkcol($collection, $path) as xs:string* {
    unzip:mkcol-recursive($collection, tokenize($path, "/") ! xmldb:encode(.))
};

(: Helper function to recursively create a collection hierarchy. :)
declare %private function unzip:mkcol($path) as xs:string* {
    unzip:mkcol('/db', substring-after($path, "/db/"))
};

(: Helper function to allow all zip entries through :)
declare %private function unzip:allow-all-entries-through($path as xs:string, $data-type as xs:string, $param as item()*) as xs:boolean {
    true()
};

(: Helper function to store zip file data :)
declare %private function unzip:store-entry($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) as element() {
    let $unzip-base-collection := $param[@name="unzip-base-collection"]/@value
    return
        if ($data-type = 'folder') then
            let $mkcol := unzip:mkcol($unzip-base-collection, $path)
            return
                <entry path="{$path}" data-type="{$data-type}"/>
        else (: if ($data-type = 'resource') :)
            let $resource-collection := concat($unzip-base-collection, '/', xmldb:encode(functx:substring-before-last($path, '/')))
            let $resource-filename := if (contains($path, '/')) then functx:substring-after-last($path, '/') else $path
            let $resource-filename := xmldb:encode($resource-filename)
            return
                try {
                    let $collection-check := if (xmldb:collection-available($resource-collection)) then () else unzip:mkcol($resource-collection)
                    let $store := xmldb:store($resource-collection, $resource-filename, $data)
                    return
                        <entry path="{$path}" data-type="{$data-type}"/>
                }
                catch * {
                    <error path="{$path}">{concat('Error storing ', $path, ': ', $err:code, $err:value, $err:description)}</error>
                }
};

(: Helper function to list zip file contents :)
declare %private function unzip:list-entry($path as xs:string, $data-type as xs:string, $data as item()?, $param as item()*) as element(entry) {
    <entry path="{$path}" data-type="{$data-type}"/>
};

(:~
 : Lists contents of zip file
 :
 : @param   $resource the full db path to the zip file
 : @returns a node listing the names of all resources in the zip file
 :) 
declare function unzip:list($resource as xs:string) as element(entries) {
    let $file := if (util:binary-doc-available($resource)) then util:binary-doc($resource) else error(xs:QName('unzip'), concat($resource, ' does not exist or is not a valid binary file'))
    let $entry-filter := unzip:allow-all-entries-through#3
    let $entry-filter-params := ()
    let $entry-data := unzip:list-entry#4
    let $entry-data-params := ()
    let $entries := compression:unzip($file, $entry-filter, $entry-filter-params, $entry-data, $entry-data-params)
    return
        <entries count="{count($entries)}">{$entries}</entries>
};

(:~
 : Unzips a zip file. Contents are stored in the same collection as the zip file.
 :
 : @param   $zip-file the full db path to the zip file
 : @returns the paths of each successfully stored file or errors describing entries that could not be stored
 :) 
declare function unzip:unzip($zip-file as xs:string) as element(entries) {
    let $zip-file-collection := functx:substring-before-last($zip-file, '/')
    let $target-collection := $zip-file-collection
    return
        unzip:unzip($zip-file, $target-collection)
};

(:~
 : Unzips a zip file. Contents are stored into $target-collection.
 :
 : @param   $zip-file the full db path to the zip file
 : @param   $target-collection where the zip file contents will be stored
 : @returns the paths of each successfully stored file or errors describing entries that could not be stored
 :) 
declare function unzip:unzip($zip-file as xs:string, $target-collection as xs:string) as element(entries) {
    let $file := if (util:binary-doc-available($zip-file)) then util:binary-doc($zip-file) else error(xs:QName('unzip'), concat($zip-file, ' does not exist or is not a valid binary file'))
    let $unzip-base-collection := if (xmldb:collection-available($target-collection)) then $target-collection else unzip:mkcol($target-collection)[last()]
    let $entry-filter := unzip:allow-all-entries-through#3
    let $entry-filter-params := ()
    let $entry-data := unzip:store-entry#4
    let $entry-data-params := <param name="unzip-base-collection" value="{$unzip-base-collection}"/>
    let $results := compression:unzip($file, $entry-filter, $entry-filter-params, $entry-data, $entry-data-params)
    return
        <entries target-collection="{$target-collection}" count-stored="{count($results[self::entry])}" count-unable-to-store="{count($results[self::error])}">{$results}</entries>
};