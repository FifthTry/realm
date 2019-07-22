
# realm
Rust / Elm base full stack web framework.

## Getting Started

These instructions will get you a copy of the realm framework's simple 'hello-world' web project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites



```
node 8
Python 3.7
Rust 1.36.0
```

### Installing

install realm_cli using pip

```
pip install realm_cli
```

And next, clone the project with any name say 'foo.'

```
realm-cli startapp foo

```
Now you can see project directory with name 'foo'.


 

## Deployment

run following command to start server locally.
```
cd foo
realm-cli debug

```
open 127.0.0.1:3000 to see programmer's anthem.

## Info

```realm.json``` mentions source directories as ```source_dirs``` for elm compilation and destination directory as ```static_dir```, further same source directories has to be mentioned in elm.json too.

Directory Structure in all elm source directories has to be same as that inside ```/src``` for rust files.

All  Backend rust files should be located in ```/src```. 


## Built With

* [realm](https://github.com/ackotech/realm/) - A web framework written in Rust and Elm.
## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
