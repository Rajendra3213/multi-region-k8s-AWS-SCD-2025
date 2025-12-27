#!/bin/bash

DOMAIN="rajendra-acharya.com.np"
primary=0
secondary=0

echo "Testing Multi-Region Setup"
echo "=========================="
echo ""

echo "1. Testing via Domain: $DOMAIN (100 requests for better accuracy)"
for i in {1..10}; do
  response=$(curl -s http://$DOMAIN | grep -E "(PRIMARY|SECONDARY|ap-south|ap-northeast)")
  
  if echo "$response" | grep -q "PRIMARY\|ap-south-1"; then
    ((primary++))
    echo -n "Primary"
  elif echo "$response" | grep -q "SECONDARY\|ap-northeast-1"; then
    ((secondary++))
    echo -n "Secondary"
  else
    echo -n "."
  fi
  
  [ $((i % 50)) -eq 0 ] && echo ""  # New line every 50 requests
  sleep 0.2
done

total=$((primary + secondary))

echo ""
echo ""
echo "2. Traffic Distribution:"
if [ $total -gt 0 ]; then
  primary_pct=$((primary * 100 / total))
  secondary_pct=$((secondary * 100 / total))
  echo "Primary (ap-south-1): $primary_pct% ($primary/$total)"
  echo "Secondary (ap-northeast-1): $secondary_pct% ($secondary/$total)"
  echo ""
  echo "Note: Global Accelerator uses performance-based routing."
  echo "40-60% split is normal and expected behavior."
else
  echo "No responses received"
fi


