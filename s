<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="style.css">
    <title>QR Code Scanner / Reader</title>
</head>
<body>
    <div class="container">
        <h1>QR Code Scanner</h1>
        <div class="button-group">
            <button id="moreButton">More</button>
        </div>
        <div id="dashboard" class="dashboard">
            <h3>Dashboard</h3>
            <p>Total Sales: Rs. <span id="total-sales">0.00</span></p>
            <p>Low Stock Items:</p>
            <ul id="low-stock-items"></ul>
        </div>

        <div id="moreOptions" class="hidden">
            <button id="option1-button">Set Barcode Values</button>
            <button id="option2-button">Add to Cart</button>
            <button id="option3-button">UPI QR Code</button>
            <button id="option4-button">Import/Export Data</button>
            <button id="option5-button">Bill History</button>
            <button id="inventory-button">Inventory</button>
        </div>

        <div id="option1" class="option">
            <div id="my-qr-reader-option1"></div>
            <div class="input-group">
                <label for="barcode">Barcode:</label>
                <input type="text" id="barcode" readonly>
            </div>
            <div class="input-group">
                <label for="product-name">Product Name:</label>
                <input type="text" id="product-name">
            </div>
            <div class="input-group">
                <label for="product-price">Product Price:</label>
                <input type="number" id="product-price" step="0.01">
            </div>
            <div class="input-group">
                <label for="product-quantity">Quantity:</label>
                <input type="number" id="product-quantity" min="0">
            </div>
            <button id="save-barcode">Save</button>
        </div>

        <div id="option2" class="option">
            <div id="my-qr-reader-option2"></div>
            <h2>Cart</h2>
            <div id="cart"></div>
            <div id="total">Total: Rs.0</div>
            <button id="generate-bill">Generate Bill</button>
            <div id="bill-qr-code"></div>
            
        </div>

        <div id="option3" class="option">
            <h2>UPI QR Code Generator</h2>
            <form id="qrForm">
                <div class="input-group">
                    <label for="upi_id">UPI ID (e.g., 9545689031@paytm):</label>
                    <input type="text" id="upi_id" name="upi_id" required>
                </div>
                <div class="input-group">
                    <label for="name">Name (e.g., hello):</label>
                    <input type="text" id="name" name="name" required>
                </div>
                <div class="input-group">
                    <label for="note">Transaction Note (e.g., note):</label>
                    <input type="text" id="note" name="note" required>
                </div>
                <button type="submit">Save UPI Details</button>
            </form>
            <div id="qrCode"></div>
        </div>

        <div id="option4" class="option">
            <h2>Import/Export Data</h2>
            <button id="download-data">Download Data</button>
            <input type="file" id="upload-data" accept=".json">
        </div>

        <div id="option5" class="option">
            <h2>Bill History</h2>
            <div id="bill-history"></div>
        </div>

        <div id="inventory-option" class="option">
            <h2>Inventory</h2>
            <div id="inventory-list"></div>
            <button id="save-inventory" style="display: none;">Save</button>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <script src="https://unpkg.com/html5-qrcode"></script>
    <script src="https://cdn.jsdelivr.net/npm/qr-code-styling/lib/qr-code-styling.js"></script>
    <script src="inventory.js"></script>
</body>
</html> function domReady(fn) {
    if (document.readyState === "complete" || document.readyState === "interactive") {
        setTimeout(fn, 1);
    } else {
        document.addEventListener("DOMContentLoaded", fn);
    }
}

window.jsPDF = window.jspdf.jsPDF;

function saveToLocalStorage(key, value) {
    localStorage.setItem(key, JSON.stringify(value));
}

function loadFromLocalStorage(key) {
    const value = localStorage.getItem(key);
    return value ? JSON.parse(value) : null;
}

domReady(function () {
    let productDetails = loadFromLocalStorage('productDetails') || {};
    let cart = [];
    let upiDetails = loadFromLocalStorage('upiDetails') || {};
    let billHistory = loadFromLocalStorage('billHistory') || [];
    let inventory = loadFromLocalStorage('inventory') || {};

    // Scanner for Option 1 (Product Setup)
    const html5QrcodeScannerOption1 = new Html5QrcodeScanner(
        "my-qr-reader-option1",
        { fps: 30, qrbox: { width: 250, height: 250 } }
    );
    html5QrcodeScannerOption1.render((decodeText) => {
        document.getElementById('barcode').value = decodeText;
        if (productDetails[decodeText]) {
            document.getElementById('product-name').value = productDetails[decodeText].name;
            document.getElementById('product-price').value = productDetails[decodeText].price;
            document.getElementById('product-quantity').value = inventory[decodeText]?.quantity || 0;
        } else {
            document.getElementById('product-name').value = '';
            document.getElementById('product-price').value = '';
            document.getElementById('product-quantity').value = '';
        }
    });

    // Scanner for Option 2 (Cart)
    const html5QrcodeScannerOption2 = new Html5QrcodeScanner(
        "my-qr-reader-option2",
        { fps: 30, qrbox: { width: 250, height: 250 } }
    );
    let lastScannedCode = '';  // To keep track of the last scanned code
    
    html5QrcodeScannerOption2.render((decodeText) => {
        if (decodeText !== lastScannedCode && productDetails[decodeText]) {
            lastScannedCode = decodeText; // Update the last scanned code
            const existingItem = cart.find(item => item.code === decodeText);
            if (!existingItem) {
                if (inventory[decodeText].quantity > 0) {
                    cart.push({ code: decodeText, quantity: 1 }); // Start with a quantity of 1
                    displayCart();
                } else {
                    alert(`Out of stock for product ${inventory[decodeText].name}!`);
                }
            } else {
                // If the item exists, do not increase the quantity automatically
                displayCart();
            }
        } else if (decodeText !== lastScannedCode) {
            // If the product is not found in the productDetails, alert the user
            alert(`Product ${decodeText} not found!`);
        }
        // Scanner continues without stopping
    });

    function displayCart() {
        const cartDiv = document.getElementById('cart');
        cartDiv.innerHTML = '';
        cart.forEach((item, index) => {
            const product = productDetails[item.code];
            const itemDiv = document.createElement('div');
            itemDiv.className = 'cart-item';
            itemDiv.innerHTML = `
                <span class="product-name">${product?.name || 'Unknown Product'}</span>
                <span class="product-price">Rs. ${product?.price?.toFixed(2) || '0.00'}</span>
                <input type="number" 
                       value="1"  // Default to 1 for display, but cart will have actual quantity
                       min="1" 
                       data-index="${index}"
                       class="quantity-input">
                <span class="item-total">Rs. ${(product?.price * item.quantity).toFixed(2) || '0.00'}</span>
            `;
            cartDiv.appendChild(itemDiv);
            
            // After appending, set the actual quantity from cart
            const quantityInput = itemDiv.querySelector('.quantity-input');
            quantityInput.value = item.quantity;
        });
        calculateTotal();
    }

    function calculateTotal() {
        const total = cart.reduce((sum, item) => {
            const product = productDetails[item.code];
            return sum + (product?.price || 0) * item.quantity;
        }, 0);
        document.getElementById('total').innerHTML = `<strong>Total:</strong> Rs. ${total.toFixed(2)}`;
    }

    // Event Listeners
    document.getElementById('cart').addEventListener('input', (e) => {
        if (e.target.classList.contains('quantity-input')) {
            const index = e.target.dataset.index;
            const newQty = parseInt(e.target.value);
            const productCode = cart[index].code;
            const oldQty = cart[index].quantity;
            
            if (!isNaN(newQty) && newQty > 0) {
                if (inventory[productCode].quantity >= newQty) {
                    cart[index].quantity = newQty;
                    displayCart();
                } else {
                    alert(`Not enough stock. Only ${inventory[productCode].quantity} left.`);
                    e.target.value = oldQty;
                }
            } else if (e.target.value === '') {
                e.target.value = '';
            } else {
                alert('Quantity must be a positive number.');
                e.target.value = oldQty;
            }
        }
    });

    document.getElementById('save-barcode').addEventListener('click', () => {
        const barcode = document.getElementById('barcode').value.trim();
        const name = document.getElementById('product-name').value.trim();
        const price = parseFloat(document.getElementById('product-price').value);
        const quantity = parseInt(document.getElementById('product-quantity').value) || 0;

        if (barcode && name && !isNaN(price) && price > 0) {
            productDetails[barcode] = { name, price };
            inventory[barcode] = { name, price, quantity };
            saveToLocalStorage('productDetails', productDetails);
            saveToLocalStorage('inventory', inventory);
            alert('Product saved successfully!');
        } else {
            alert('Invalid input! Please check all fields.');
        }
    });

    // PDF Generation
   document.getElementById('generate-bill').addEventListener('click', async () => {
        try {
            // Validate UPI details
            if (!upiDetails.upiId || !upiDetails.name || !upiDetails.note) {
                throw new Error('Please configure UPI details first');
            }
    
            // Calculate total
            const totalAmount = cart.reduce((sum, item) => {
                const product = productDetails[item.code];
                return sum + (product?.price || 0) * item.quantity;
            }, 0);
    
            // Generate UPI URL
            const upiUrl = `upi://pay?pa=${upiDetails.upiId}` +
                           `&pn=${encodeURIComponent(upiDetails.name)}` +
                           `&am=${totalAmount.toFixed(2)}` +
                           `&cu=INR` +
                           `&tn=${encodeURIComponent(upiDetails.note)}`;
    
            // Create QR Code
            const qrCode = new QRCodeStyling({
                width: 150, // Increased for clarity, scaled in PDF
                height: 150,
                data: upiUrl,
                dotsOptions: {
                    color: "#000",
                    type: "rounded"
                },
                backgroundOptions: {
                    color: "#ffffff"
                }
            });
    
            // Render QR Code
            const qrContainer = document.getElementById('bill-qr-code');
            qrContainer.innerHTML = '';
            qrCode.append(qrContainer);
    
            // Wait for QR code rendering
            await new Promise(resolve => setTimeout(resolve, 500));
    
            // Printer dimensions
            const pageWidth = 48;    // 2-inch printer width in mm
            const margin = 1;        // Small margin to maximize space
            const maxLineWidth = pageWidth - (margin * 2); // Usable width: 46mm
            const lineHeight = 4;    // Increased for readability
    
            // Calculate content height
            let contentHeight = 0;
            const headerHeight = lineHeight * 4; // Title + Date + Time + Separator
            const footerHeight = lineHeight * 2; // Total + spacing
            const qrHeight = 40;         // Increased QR code size
            const paddingBottom = 8;     // Slightly increased padding
    
            // Items height
            const itemsHeight = cart.length === 0 
                ? lineHeight 
                : cart.length * lineHeight;
            const separatorHeight = lineHeight * 2; // Two separators
    
            // Total height
            contentHeight = headerHeight + itemsHeight + separatorHeight + 
                           footerHeight + qrHeight + paddingBottom;
    
            // Create PDF with calculated dimensions
            const doc = new jsPDF({
                orientation: 'portrait',
                unit: 'mm',
                format: [pageWidth, contentHeight] // 48mm width, dynamic height
            });
    
            doc.setFont("courier");
            doc.setFontSize(8); // Increased font size for visibility
    
            let yPos = margin; // Start with small top margin
    
            // Header
            doc.setFontSize(10); // Larger header
            doc.text("INVOICE", pageWidth / 2, yPos, { align: 'center' });
            yPos += lineHeight;
    
            // Date and Time
            doc.setFontSize(8);
            doc.text(`Dt:${new Date().toLocaleDateString()}`, margin, yPos);
            yPos += lineHeight;
            doc.text(`Tm:${new Date().toLocaleTimeString()}`, margin, yPos);
            yPos += lineHeight;
    
            // Separator
            doc.text("-".repeat(maxLineWidth / 2), pageWidth / 2, yPos, { align: 'center' });
            yPos += lineHeight;
    
            // Items or Empty Message
            if (cart.length === 0) {
                doc.text("No Items", margin, yPos);
                yPos += lineHeight;
            } else {
                cart.forEach(item => {
                    const product = productDetails[item.code];
                    const name = (product?.name || 'Unk').substring(0, 12).padEnd(12, ' ');
                    const qty = item.quantity.toString().padStart(2, ' ');
                    const amount = (product?.price * item.quantity).toFixed(2).padStart(7, ' ');
                    const itemLine = `${name}x${qty}Rs${amount}`;
                    doc.text(itemLine.substring(0, maxLineWidth), margin, yPos);
                    yPos += lineHeight;
                });
            }
    
            // Separator
            doc.text("-".repeat(maxLineWidth / 2), pageWidth / 2, yPos, { align: 'center' });
            yPos += lineHeight;
    
            // Total
            doc.text(`Tot:Rs${totalAmount.toFixed(2)}`, pageWidth / 2, yPos, { align: 'center' });
            yPos += lineHeight * 2;
    
            // Add QR Code
            const qrCanvas = qrContainer.querySelector('canvas');
            if (qrCanvas) {
                const qrData = qrCanvas.toDataURL('image/png');
                const qrWidth = 40; // Increased to 40mm for visibility
                const qrX = (pageWidth - qrWidth) / 2; // Center QR code
                doc.addImage(qrData, 'PNG', qrX, yPos, qrWidth, qrWidth);
                yPos += qrHeight;
            }
    
            // Save to history
            billHistory.push({
                date: new Date().toLocaleString(),
                total: totalAmount.toFixed(2),
                items: [...cart]
            });
            saveToLocalStorage('billHistory', billHistory);
    
            // Update inventory and clear cart
            cart.forEach(item => {
                updateInventory(item.code, item.quantity);
            });
            cart = [];
            displayCart();
            updateDashboard();
    
            // Open PDF
            const pdfBlob = doc.output('blob');
            window.open(URL.createObjectURL(pdfBlob), '_blank');
    
        } catch (error) {
            alert(`Error: ${error.message}`);
            console.error(error);
        }
    });
    
    // UPI Form Handler (unchanged)
    document.getElementById('qrForm').addEventListener('submit', (e) => {
        e.preventDefault();
        upiDetails = {
            upiId: document.getElementById('upi_id').value.trim(),
            name: document.getElementById('name').value.trim(),
            note: document.getElementById('note').value.trim()
        };
        saveToLocalStorage('upiDetails', upiDetails);
        alert('UPI details saved!');
    });
    // Bill History Display
    document.getElementById('option5-button').addEventListener('click', () => {
        const historyContainer = document.getElementById('bill-history');
        historyContainer.innerHTML = '';
        
        billHistory.forEach((bill, index) => {
            const billElement = document.createElement('div');
            billElement.className = 'bill-entry';
            billElement.innerHTML = `
                <h3>Bill #${index + 1}</h3>
                <p>Date: ${bill.date}</p>
                <ul>
                    ${bill.items.map(item => `
                        <li>${productDetails[item.code]?.name || 'Unknown'} 
                        (x${item.quantity}) - Rs. ${(productDetails[item.code]?.price * item.quantity).toFixed(2)}</li>
                    `).join('')}
                </ul>
                <p>Total: Rs. ${bill.total}</p>
                <hr>
            `;
            historyContainer.appendChild(billElement);
        });
    });

    // Inventory Management
    function updateInventory(barcode, quantityChange) {
        if (inventory[barcode]) {
            inventory[barcode].quantity -= quantityChange;
            if (inventory[barcode].quantity < 0) {
                inventory[barcode].quantity = 0; // Ensure no negative stock
            }
            saveToLocalStorage('inventory', inventory);
        }
    }

    function displayInventory() {
        const inventoryList = document.getElementById('inventory-list');
        inventoryList.innerHTML = '';
        for (const [barcode, data] of Object.entries(inventory)) {
            const item = document.createElement('div');
            item.innerHTML = `
                <span>${data.name}</span>
                <span>Price: Rs. ${data.price.toFixed(2)}</span>
                <span>Quantity: <input type="number" value="${data.quantity}" data-barcode="${barcode}" class="edit-quantity"></span>
                <button data-barcode="${barcode}" class="edit-product">Edit</button>
            `;
            inventoryList.appendChild(item);
        }

        // Event listeners for editing quantity:
        document.querySelectorAll('.edit-quantity').forEach(input => {
            input.addEventListener('change', function() {
                const barcode = this.getAttribute('data-barcode');
                const newQuantity = parseInt(this.value);
                if (newQuantity >= 0) {
                    inventory[barcode].quantity = newQuantity;
                    document.getElementById('save-inventory').style.display = 'block'; // Show save button
                } else {
                    alert('Quantity cannot be negative!');
                    this.value = inventory[barcode].quantity; // Reset to previous value
                }
            });
        });

        // Event listener for editing product details
        document.querySelectorAll('.edit-product').forEach(button => {
            button.addEventListener('click', function() {
                const barcode = this.getAttribute('data-barcode');
                const product = inventory[barcode];
                document.getElementById('barcode').value = barcode;
                document.getElementById('product-name').value = product.name;
                document.getElementById('product-price').value = product.price;
                document.getElementById('product-quantity').value = product.quantity;
                switchToOption1(); // Switch to Set Barcode Values to allow editing
                document.getElementById('save-inventory').style.display = 'block'; // Show save button
            });
        });

        // Save button event listener
        document.getElementById('save-inventory').addEventListener('click', function() {
            saveToLocalStorage('inventory', inventory);
            this.style.display = 'none'; // Hide save button after saving
            alert('Inventory saved!');
            switchToInventory(); // Refresh inventory view
        });
    }

    function updateDashboard() {
        let totalSales = 0;
    
        billHistory.forEach(bill => {
            totalSales += parseFloat(bill.total);
        });
    
        document.getElementById('total-sales').textContent = totalSales.toFixed(2);
    
        const lowStockList = document.getElementById('low-stock-items');
        lowStockList.innerHTML = '';
        Object.entries(inventory).filter(([_, item]) => item.quantity <= 5).forEach(([barcode, item]) => {
            const li = document.createElement('li');
            li.textContent = `${item.name} (${item.quantity} left)`;
            lowStockList.appendChild(li);
        });
    }

    // Show/Hide Options
    function showMoreOptions() {
        const moreOptions = document.getElementById('moreOptions');
        moreOptions.classList.toggle('hidden');

        // Remove any existing click listeners to avoid duplication
        document.body.removeEventListener('click', hideOptions);
        document.body.removeEventListener('touchstart', hideOptions);

        // Add new listener to hide options when clicking outside
        setTimeout(() => {
            document.body.addEventListener('click', hideOptions);
            document.body.addEventListener('touchstart', hideOptions);
        }, 10); // Small delay to prevent immediate closing
    }

    function hideOptions(e) {
        const moreOptions = document.getElementById('moreOptions');
        if (moreOptions && !moreOptions.contains(e.target) && e.target !== moreButton) {
            moreOptions.classList.add('hidden');
        }
    }

    function switchToOption(optionId) {
        document.querySelectorAll('.option').forEach(option => option.style.display = 'none');
        document.getElementById('dashboard').style.display = 'block'; // Show dashboard by default
        document.getElementById(optionId).style.display = 'block';
        document.getElementById('moreOptions').classList.add('hidden'); // Hide options when switching
    }

    function switchToOption1() {
        switchToOption('option1');
    }

    function switchToOption2() {
        switchToOption('option2');
    }

    function switchToOption3() {
        switchToOption('option3');
    }

    function switchToOption4() {
        switchToOption('option4');
    }

    function switchToOption5() {
        switchToOption('option5');
    }

    function switchToInventory() {
        switchToOption('inventory-option');
        displayInventory();
    }

    let moreButton = document.getElementById('moreButton');
    if (moreButton) {
        ['click', 'touchstart'].forEach(event => {
            moreButton.removeEventListener(event, showMoreOptions);
        });

        moreButton.addEventListener('touchstart', function(e) {
            e.stopPropagation();
            e.preventDefault();
            showMoreOptions();
        });

        moreButton.addEventListener('click', showMoreOptions);
    }

    // Add click listeners for the other options buttons
    document.getElementById('option1-button').addEventListener('click', switchToOption1);
    document.getElementById('option2-button').addEventListener('click', switchToOption2);
    document.getElementById('option3-button').addEventListener('click', switchToOption3);
    document.getElementById('option4-button').addEventListener('click', switchToOption4);
    document.getElementById('option5-button').addEventListener('click', switchToOption5);
    document.getElementById('inventory-button').addEventListener('click', switchToInventory);

    // Initial setup
    switchToOption2(); // Default to cart view
    updateDashboard();
});body {
    font-family: Arial, sans-serif;
    background-color: #f5f5f5;
    margin: 0;
    padding: 0;
    display: flex;
    justify-content: center;
    align-items: start;
    height: 100vh;
}

.container {
    max-width: 800px;
    background-color: #ffffff;
    padding: 30px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    border-radius: 8px;
    text-align: center;
    width: 100%;
    height: calc(100vh - 60px); /* Adjust based on your header/footer if any */
    overflow-y: auto;
}

.element {
    margin-bottom: 22px;
}

.input-group {
    text-align: left;
    margin-bottom: 10px;
}

input {
    width: 100%;
    padding: 12px;
    border: 1px solid #ccc;
    border-radius: 5px;
}

button {
    padding: 10px 20px;
    font-size: 16px;
    cursor: pointer;
    border: none;
    background-color: #007bff;
    color: white;
    border-radius: 5px;
    transition: background-color 0.3s;
    margin-bottom: 22px;
}

button:hover {
    background-color: #0056b3;
}

@media (max-width: 600px) {
    .container {
        padding: 20px;
    }

    input {
        width: 92%;
    }

    button {
        width: 100%;
    }
}

.option {
    display: none;
    margin-top: 20px; /* Space from the More button */
}

.hidden {
    display: none;
}

.dashboard {
    margin-bottom: 20px;
}

.button-group {
    margin-bottom: 20px;
}

#moreButton {
    display: block;
    visibility: visible;
    cursor: pointer;
    z-index: 10;
    position: relative;
    padding: 10px 20px;
    font-size: 16px;
}

#moreOptions {
    position: relative; /* Fixed for mobile, relative for desktop */
}

.dashboard {
    margin-bottom: 20px;
    padding: 15px;
    background-color: #f8f9fa;
    border-radius: 8px;
    text-align: left;
}

.dashboard h3 {
    margin-top: 0;
    margin-bottom: 15px;
    color: #333;
}

.dashboard p {
    margin: 5px 0;
}

.dashboard ul {
    padding-left: 20px;
    margin: 0;
}

.dashboard li {
    margin-bottom: 5px;
}

#bill-history {
    max-height: 400px;
    overflow-y: auto;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 5px;
}

.bill-entry {
    margin-bottom: 10px;
}

#inventory-list > div {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid #eee;
    padding: 5px 0;
}

#inventory-list input {
    width: 50px; /* Adjust as needed */
}

#inventory-list button {
    padding: 5px 10px;
    font-size: 12px;
}

/* Ensure More button is always clickable */
.option::after {
    content: '';
    display: block;
    height: 50px; /* Height of the More button */
    pointer-events: none; /* Allows click through */
}   ///// add a logic that user send bill to the customer though whatsapp massage. user set a number values also, every customer get a unique barcode. that barcode use as a save customer details and when user scan that unique barcode in cart it send whatsapp bill. if user not scan the cutomer barcode scan it generate bill pdf and print like normal. but when user scan the barcode of customer it it send whatsamassage. the user mobile number and user name save in set barcode values. add Product Name:/ user name Product Price:/ customer number. it save in data base local .  the user send bill though whatsapp logic work as a when the barcode values start with qrwale this name that barcode customer id send bill in whatsapp. when user
