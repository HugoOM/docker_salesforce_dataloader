### Command to run from /dataloader

```bash
docker run -t -v ~/VSCode_Projects/docker_dataloader/config:/mnt/config -v ~/VSCode_Projects/docker_dataloader/jobs:/mnt/jobs --env-file ./.env hmonette/sf_dataloader
```
