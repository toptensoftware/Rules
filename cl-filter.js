#!/usr/bin/env node

let fs = require('fs');
let child_process = require("child_process");

// Run a command
async function run(cmd, args, opts, stdioCallback, stderrCallback)
{
    // Merge options
    opts = Object.assign({shell: true}, opts);

    // Inherit stdio or filter it?
    if (!stdioCallback)
    {
        opts.stdio = 'inherit';
    }

    if (!stderrCallback)
    {
        opts.stdio = 'inherit';
    }

    let sbout = "";
    function stdout_data(data)
    {
        sbout += data;
        while (true)
        {
            let nlPos = sbout.indexOf('\n');
            if (nlPos < 0)
                break;

            let crPos = nlPos;
            if (crPos > 0 && sbout[crPos-1] == '\r')
                crPos--;

            stdioCallback(sbout.substring(0, crPos));
            sbout = sbout.substring(nlPos+1);
        }
    }


    let sberr = "";
    function stderr_data(data)
    {
        sberr += data;
        while (true)
        {
            let nlPos = sberr.indexOf('\n');
            if (nlPos < 0)
                break;

            let crPos = nlPos;
            if (crPos > 0 && sberr[crPos-1] == '\r')
                crPos--;

            stdioCallback(sberr.substring(0, crPos));
            sberr = sberr.substring(nlPos+1);
        }
    }

    function stdflush()
    {
        if (sbout.length > 0)
        {
            stdioCallback(sbout);
            sbout = "";
        }
        if (sberr.length > 0)
        {
            stdioCallback(sberr);
            sberr = "";
        }
    }

    return new Promise((resolve, reject) => {

        // Spawn process
        let child = child_process.spawn(cmd, args, opts);

        child.on('exit', code => {
            stdflush();
            resolve(code);
        });

        child.on('error', err => {
            stdflush();
            reject(err);
        });
    
        if (stdioCallback)
        {
            child.stdout.on('data', stdout_data);
            child.stderr.on('data', stderr_data);
        }
    });
}


// Main
async function main(args)
{
    // Find the name of the file we're compiling
    var sourceFile = [];
    var objFile;
    var showIncludes = false;
    for (let i=0; i<args.length; i++)
    {
        //console.log("arg:", i, args[i]);
        if (args[i].endsWith(".cpp") || args[i].endsWith(".c"))
        {
            sourceFile = args[i];
        }
        else if (args[i].startsWith("/Fo"))
        {
            objFile = args[i].substr(3);
        }
        else if (args[i] == "/showIncludes")
        {
            showIncludes = true;
        }

    }

    var depFile = objFile.substr(0, objFile.lastIndexOf(".")) + ".d";
    var deps = objFile + ": " + sourceFile;
    var deps2 = "";

    var exitCode = await run(args[0], args.slice(1), null, 
        (line) => 
        {
            // STDOUT handler
            if (line.startsWith("Note: including file:"))
            {
                var file = line.substr(21).trim();
                // Don't include system files
                if (!file.startsWith("C:\\Program Files"))
                {
                    deps += " \\\n " + file;
                    deps2 += file + ":" + "\n\n";
                }
            }
            else
            {
                // Suppress printing name of source file
                if (sourceFile == line)
                    return;

                // Other output message
                process.stdout.write(line + "\r\n");
            }
        },
        (line) =>
        {
            // STDERR handler
            process.stderr.write(line + "\r\n");
        }
    );

    if (showIncludes)
        fs.writeFileSync(depFile, deps + "\n\n" + deps2, "utf8");
    process.exit(exitCode);
}


// Invoke main
main(process.argv.slice(2));

