provider "aws" { 

region = "ap-south-1"
profile = "default"

}

resource "aws_instance"  "webos1"  {

ami = "ami-010aff33ed5991201"
instance_type = "t2.micro"
security_groups = [ "webport-allow" ]
key_name = "terraform_key"
tags = { 
    Name = "Ansible-Master"
     }
}
output "my_public_ip_is" {
value = aws_instance.webos1.public_ip
}

resource "aws_instance"  "os2"  {

ami = "ami-010aff33ed5991201"
instance_type = "t2.micro"
security_groups = [ "Allow-All" ]
key_name = "terraform_key"
tags = { 
    Name = "K8s-Master"
    }
}

output "my_public_ip_for_k8s-master" {
value = aws_instance.os2.public_ip
}

resource "aws_instance"  "os3"  {

ami = "ami-010aff33ed5991201"
instance_type = "t2.micro"
security_groups = [ "Allow-All" ]
key_name = "terraform_key"
tags = { 
    Name = "K8s-Slave"
    }
}

output "my_public_ip_for_k8s-slave" {
value = aws_instance.os3.public_ip
}


resource  "null_resource"  "nullremote5" {

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Ayush/Downloads/terraform_key.pem")
    host     = aws_instance.webos1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install ansible2 -y"
    ]
  }
provisioner "file" {
    source      = "k8s-master.yml"
    destination = "/home/ec2-user/k8s-master.yml"
    }

provisioner "file" {
    source      = "k8s-slave-aws.yml"
    destination = "/home/ec2-user/k8s-slave-aws.yml"
    }

provisioner "file" {
    source      = "terraform_key.pem"
    destination = "/home/ec2-user/terraform_key.pem"
    }

provisioner "file" {
    content     = "[k8s-master]\n${aws_instance.os2.public_ip}\n[k8s-slave]\n${aws_instance.os3.public_ip}"
    destination = "/home/ec2-user/hosts.txt"
    }
provisioner "file" {
        source = "ansible.cfg"
        destination = " /home/ec2-user/ansible.cfg"  
    }
provisioner "remote-exec" {
    inline = [
    "sudo cp /home/ec2-user/ansible.cfg   /etc/ansible/ansible.cfg",
    "sudo ansible-playbook k8s-master.yml",
    "sudo ansible-playbook k8s-slave-aws.yml"
    ]
  }
  depends_on = [aws_instance.webos1, aws_instance.os2,aws_instance.os3]
}
