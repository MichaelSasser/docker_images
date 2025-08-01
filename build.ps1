param(
    [Parameter(ValueFromPipeline)]
    [string]$progress,
    [Parameter(ValueFromPipeline)]
    [string]$owner = "${env:IMAGE_LABEL_OWNER}",
    [Parameter(ValueFromPipeline)]
    [string]$repository = "${env:IMAGE_LABEL_REPO}",
    [Parameter(ValueFromPipeline)]
    [string]$slug = 'MichaelSasser/ubuntu',
    [Parameter(ValueFromPipeline)]
    [string[]]$tags,
    [Parameter(ValueFromPipeline)]
    [string]$tag,
    [Parameter(ValueFromPipeline)]
    [string]$node = "${env:NODE}",
    [Parameter(ValueFromPipeline)]
    [string]$distro = 'ubuntu',
    [Parameter(ValueFromPipeline)]
    [string]$type = "${env:TYPE}",
    [Parameter(ValueFromPipeline)]
    [string]$runner = "${env:RUNNER}",
    [Parameter(ValueFromPipeline)]
    [string]$image = 'ubuntu',
    [Parameter(ValueFromPipeline)]
    [string]$platforms = "${env:PLATFORMS}",
    [Parameter(ValueFromPipeline)]
    [string]$build_tag = "${env:BUILD_TAG}",
    [Parameter(ValueFromPipeline)]
    [string]$build_tag_version = "${env:BUILD_TAG_VERSION}",
    [Parameter(ValueFromPipeline)]
    [string]$build_ref = "${env:BUILD_REF}",
    [Parameter(ValueFromPipeline)]
    [string]$from_image = "${env:FROM_IMAGE}",
    [Parameter(ValueFromPipeline)]
    [string]$from_tag = "${env:FROM_TAG}",
    [Parameter(ValueFromPipeline)]
    [switch]$push
)

# https://stackoverflow.com/a/33545660
function Flatten-Array{
    $input | ForEach-Object{
        if (($_ -is [array]) -and (-not ($_ -is [string])) ){$_ | Flatten-Array}else{$_}
    } | Where-Object{![string]::IsNullorEmpty($_)}
}

function exec() {
    $path, $myargs = $args | Flatten-Array
    & "$path" $myargs
    if($LASTEXITCODE -ne 0) {
        throw "$($args | Flatten-Array) failed with exit code $LASTEXITCODE"
    }
}
function exec_out() {
    $path, $myargs = $args | Flatten-Array
    $stdout = "$(& "$path" $myargs)"
    if($LASTEXITCODE -ne 0) {
        throw "$($args | Flatten-Array) failed with exit code $LASTEXITCODE, error: $stdout"
    }
    return "$stdout"
}

$manifest = "$(New-Guid)-manifest:latest"

exec buildah manifest create "$manifest"

ForEach($platform in $platforms.Split(",")) {
    $intermediatetag = "$(New-Guid)-intermediate:latest"

    $plat = $platform.Split("/")

    $arguments = @(
        "buildah",
        "build",
        "--ulimit=nofile=4096:4096",
        "--platform=${platform}",
        "--build-arg=TARGETARCH=$($plat[1])"
        "--build-arg=NODE_VERSION=${node}",
        "--build-arg=DISTRO=${distro}",
        "--build-arg=TYPE=${type}",
        "--build-arg=RUNNER=${runner}",
        "--build-arg=BUILD_DATE=$((Get-Date).ToString('u'))",
        "--build-arg=BUILD_OWNER=${owner}",
        "--build-arg=BUILD_OWNER_MAIL=${owner}",
        "--build-arg=BUILD_REPO=${repository}",
        "--build-arg=BUILD_TAG=${build_tag}",
        "--build-arg=BUILD_TAG_VERSION=${build_tag_version}",
        "--build-arg=BUILD_REF=${build_ref}",
        "--build-arg=FROM_IMAGE=${from_image}",
        "--build-arg=FROM_TAG=${from_tag}",
        "--file=./linux/${image}/Dockerfile",
        "--tag=${intermediatetag}",
        "--format=docker",
        '.'
    )

    exec $arguments
    $containerName = New-Guid
    # buildah bug: https://github.com/containers/buildah/commit/4b7d3555bfa4440c3c5264ae44b93822e10deec0
    # The arm variant is dropped in the previous step this causes a failure here
    exec buildah from --format=docker --name "$containerName-container" --platform "$($plat[0])/$($plat[1])" "$intermediatetag"
    $containerpath = exec_out buildah mount "$containerName-container"
    $envfileContent = Get-Content "$containerpath/etc/environment"
    $arguments = @(
        "buildah",
        "config"
    )
    ForEach($envline in $envfileContent) {
        $arguments += "--env","$envline"
    }
    $arguments += @("$containerName-container")
    exec $arguments
    exec buildah unmount "$containerName-container"
    exec buildah commit --format=docker "$containerName-container" "$containerName-image"
    exec buildah manifest add "$manifest" "$containerName-image"
}

if($push -eq $true) {
   ForEach($t in ($tags + ($tag -ne '' ? @("$tag") : @()))) {
        $retries = 0
        $maxRetries = 3
        $success = $false

        while(-not $success -and $retries -lt $maxRetries) {
            try {
                exec buildah manifest push --all "$manifest" "docker://$t"
                $success = $true
            } catch {
                $retries++
                Write-Host "Error encountered during push. Retrying... ($retries/$maxRetries)"
                Start-Sleep -Seconds 2
            }
        }

        if(-not $success) {
            Write-Host "Failed to push after $maxRetries attempts."
            exit 1
        }
    }
}
