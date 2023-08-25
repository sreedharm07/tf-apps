locals{
  names= "${var.env}-${var.components}"
  tags= merge(var.tags,{tf-module=apps},{env=var.env})

}