#!/bin/bash

sfdx force:source:push
sfdx force:user:permset:assign --permsetname=Event_Admin_Access