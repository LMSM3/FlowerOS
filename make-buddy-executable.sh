#!/bin/bash
# Make buddy window scripts executable

echo "Making buddy window scripts executable..."
echo ""

chmod +x buddy-windows.sh
echo "✓ buddy-windows.sh"

chmod +x relay-auto-test.sh
echo "✓ relay-auto-test.sh"

chmod +x buddy-presets.sh
echo "✓ buddy-presets.sh"

echo ""
echo "All buddy window scripts are now executable!"
echo ""
echo "Try:"
echo "  bash relay-auto-test.sh"
echo ""
sleep 2
#start-sleep -s 2
echo " This is example code of the executable desktop application CLI pipeline helper." 