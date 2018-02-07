provider "aws" {
  access_key = "AKIAJJ6SGZYHEL5ZKVSQ"
  secret_key= "LoxhoMP4hWRBMoqBavBJ7gMmPfbgBKYDFie2mnDz"
  region     = "us-east-1"
}

resource "aws_instance" "terra-sample" {
  ami           = "ami-f4cc1de2"
  instance_type = "t2.nano"
}