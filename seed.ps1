$SUBNET_ID = (aws ec2 describe-subnets --filters "Name=tag:Name,Values=ssr-private-1" --query "Subnets[0].SubnetId" --output text).Trim()
$SG_ID = (aws ec2 describe-security-groups --filters "Name=group-name,Values=ssr-sg-ecs-task" --query "SecurityGroups[0].GroupId" --output text).Trim()

$netConfig = (@{ awsvpcConfiguration = @{ subnets = @($SUBNET_ID); securityGroups = @($SG_ID); assignPublicIp = "DISABLED" } } | ConvertTo-Json -Compress)

$script = "const {PrismaClient}=require('@prisma/client');const db=new PrismaClient();db.item.createMany({data:[{name:'Item1',description:'Desc1'},{name:'Item2',description:'Desc2'},{name:'Item3',description:'Desc3'}]}).then(()=>console.log('seeded')).finally(()=>db.`$disconnect())"

$overrides = (@{
    containerOverrides = @(@{
        name = "ssr"
        command = @("node", "-e", $script)
    })
} | ConvertTo-Json -Compress -Depth 5)

[System.IO.File]::WriteAllText("$env:TEMP\net_config.json", $netConfig, [System.Text.Encoding]::ASCII)
[System.IO.File]::WriteAllText("$env:TEMP\overrides.json", $overrides, [System.Text.Encoding]::ASCII)

aws ecs run-task --cluster ssr-cluster --task-definition ssr-task --launch-type FARGATE --network-configuration "file://$env:TEMP/net_config.json" --overrides "file://$env:TEMP/overrides.json"
